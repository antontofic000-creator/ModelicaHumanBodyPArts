within ModelicaHumanBodyPArts;
  package Contact
    "Distributed unilateral foot-ground contact and ground-wrench accounting"
    extends Modelica.Icons.Package;
  
    model ContactPoint
      "One unilateral compliant point contact with regularized Coulomb friction"
      import SI = Modelica.Units.SI;
    
      parameter SI.Position groundHeight=0
        "World z coordinate of horizontal contact plane";
      parameter Real kNormal(unit="N/m")=2e5
        "Penalty stiffness; computational contact parameter, not tissue stiffness";
      parameter Real cNormal(unit="N.s/m")=500
        "Penalty damping; computational contact parameter";
      parameter Real mu(min=0)=0.7
        "Regularized Coulomb friction coefficient";
      parameter SI.Velocity vSlip=0.01
        "Velocity scale for tanh friction regularization";
      parameter SI.Velocity vEps=1e-6
        "Regularization used in tangential direction normalization";
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_contact;
    
      output SI.Position rWorld[3];
      output SI.Velocity vWorld[3];
      output SI.Length penetration;
      output SI.Force normalForce;
      output SI.Force forceWorld[3];
      output Real frictionUtilization;
      output Boolean active;
    
    protected
      SI.Velocity penetrationRate;
      SI.Velocity vTangential;
      SI.Velocity vTangentialReg;
      SI.Force frictionMagnitude;
    
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition position(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsoluteVelocity velocity(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
    
      Modelica.Mechanics.MultiBody.Forces.WorldForce worldForce(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world);
    
    equation
      assert(kNormal>0 and cNormal>=0 and mu>=0 and vSlip>0 and vEps>0,
        "Invalid contact stiffness/damping/friction regularization parameters.");
      connect(frame_contact, position.frame_a);
      connect(frame_contact, velocity.frame_a);
      connect(frame_contact, worldForce.frame_b);
    
      rWorld = position.r;
      vWorld = velocity.v;
    
      penetration = max(0, groundHeight - rWorld[3]);
      penetrationRate = if penetration > 0 then -vWorld[3] else 0;
    
      // Linear unilateral penalty law. The max() prevents tensile contact.
      normalForce =
        if penetration > 0 then
          max(0, kNormal*penetration + cNormal*penetrationRate)
        else 0;
    
      vTangential = sqrt(vWorld[1]^2 + vWorld[2]^2);
      vTangentialReg = sqrt(vTangential^2 + vEps^2);
      frictionMagnitude =
        mu*normalForce*Modelica.Math.tanh(vTangential/vSlip);
    
      forceWorld[1] = -frictionMagnitude*vWorld[1]/vTangentialReg;
      forceWorld[2] = -frictionMagnitude*vWorld[2]/vTangentialReg;
      forceWorld[3] = normalForce;
    
      worldForce.force = forceWorld;
    
      frictionUtilization =
        if normalForce > 1e-9 then
          sqrt(forceWorld[1]^2 + forceWorld[2]^2)/(mu*normalForce + 1e-12)
        else 0;
    
      active = normalForce > 0;
    
      annotation(Documentation(info="<html>
      <p>v0.3 deliberately uses a simple unilateral Kelvin-Voigt penalty normal
      law and smooth Coulomb friction. These are numerical contact laws used to
      establish force/moment routing and verification infrastructure. Their
      parameters must not be interpreted as anatomical plantar stiffness or a
      universal shoe-floor friction value.</p>
      <p>The applied force is resolved in the world frame and acts at the
      connected plantar frame.</p>
      </html>"));
    end ContactPoint;
  
    model GroundWrenchSensor
      "Aggregate distributed contact forces and free moments into a complete ground wrench"
      import SI = Modelica.Units.SI;
    
      parameter Integer nZones(min=1)=6;
      parameter SI.Position referencePoint[3]={0,0,0};
      parameter SI.Force fzEps=1e-6;
      parameter SI.Position contactPlaneHeight=0
        "World z of plane on which the wrench-equivalent COP is reported";
    
      input SI.Position rWorld[nZones,3];
      input SI.Force forceWorld[nZones,3];
      input SI.Torque freeMomentWorld[nZones,3];
    
      output SI.Force resultantForce[3];
      output SI.Torque resultantMoment[3]
        "Moment about referencePoint";
      output SI.Position cop[2]
        "COP x/y on the horizontal ground plane; zero if vertical load is negligible";
      output Boolean copValid "False when compressive resultant vertical load is too small";
      output SI.Torque freeMomentAtCOP "Residual vertical moment after moving wrench to COP";
      output SI.Torque yawFromShear;
      output SI.Torque yawFromFreeMoment;
      output SI.Torque yawTotal;
    
    equation
      // v0.7.3: scalar reduction equations avoid an OpenModelica 1.27.1
      // backend adjacency failure caused by aliased outputs of the old algorithm.
      // The wrench and reporting-plane definitions are unchanged.
      for j in 1:3 loop
        resultantForce[j] = sum(forceWorld[:,j]);
      end for;
      resultantMoment[1] = sum((rWorld[i,2]-referencePoint[2])*forceWorld[i,3]
        - (rWorld[i,3]-referencePoint[3])*forceWorld[i,2]
        + freeMomentWorld[i,1] for i in 1:nZones);
      resultantMoment[2] = sum((rWorld[i,3]-referencePoint[3])*forceWorld[i,1]
        - (rWorld[i,1]-referencePoint[1])*forceWorld[i,3]
        + freeMomentWorld[i,2] for i in 1:nZones);
      resultantMoment[3] = sum((rWorld[i,1]-referencePoint[1])*forceWorld[i,2]
        - (rWorld[i,2]-referencePoint[2])*forceWorld[i,1]
        + freeMomentWorld[i,3] for i in 1:nZones);
      yawFromShear = sum((rWorld[i,1]-referencePoint[1])*forceWorld[i,2]
        - (rWorld[i,2]-referencePoint[2])*forceWorld[i,1] for i in 1:nZones);
      yawFromFreeMoment = sum(freeMomentWorld[:,3]);
      yawTotal = yawFromShear + yawFromFreeMoment;
      copValid = resultantForce[3] > fzEps;
      if copValid then
        cop[1] = referencePoint[1]
          + (contactPlaneHeight-referencePoint[3])*resultantForce[1]/resultantForce[3]
          - resultantMoment[2]/resultantForce[3];
        cop[2] = referencePoint[2]
          + (contactPlaneHeight-referencePoint[3])*resultantForce[2]/resultantForce[3]
          + resultantMoment[1]/resultantForce[3];
        freeMomentAtCOP = resultantMoment[3]
          - (cop[1]-referencePoint[1])*resultantForce[2]
          + (cop[2]-referencePoint[2])*resultantForce[1];
      else
        cop[1] = 0;
        cop[2] = 0;
        freeMomentAtCOP = 0;
      end if;
    
      annotation(Documentation(info="<html>
      <p>v0.7 distinguishes the reporting-plane COP from the normal-load centroid.
      Reporting-point height is included in the wrench transformation. A zero
      stored COP when copValid=false is not a measured/support point.</p>
      <p>This component intentionally reports the complete resultant force and
      moment, and explicitly decomposes yaw into the shear-moment contribution
      plus any supplied free/torsional contact moment. Medial normal pressure by
      itself is therefore not treated as yaw torque.</p>
      </html>"));
    end GroundWrenchSensor;
  
    model PlantarContact
      "Six-zone unilateral plantar contact with complete ground-wrench reconstruction"
      import SI = Modelica.Units.SI;
    
      parameter Integer nZones=6;
      parameter SI.Position groundHeight=0;
      parameter Real kNormal(unit="N/m")=2e5;
      parameter Real cNormal(unit="N.s/m")=500;
      parameter Real mu(min=0)=0.7;
      parameter SI.Velocity vSlip=0.01;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0
        "Fraction of residual local Coulomb budget, v0.7";
      parameter SI.Length patchRadius[nZones]=fill(0,nZones);
      parameter SI.AngularVelocity omegaTorsionSlip=0.05;
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a plantarFrames[nZones];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_torsion
        "Rigid foot frame receiving the optional pure yaw contact moment";
    
      output SI.Force zoneForceWorld[nZones,3];
      output SI.Force zoneNormalForce[nZones];
      output Real frictionUtilization[nZones];
      output Boolean zoneActive[nZones];
      output SI.Position zonePositionWorld[nZones,3];
    
      output SI.Force groundReactionForce[3];
      output SI.Torque groundMoment[3];
      output SI.Position cop[2];
      output Boolean copValid;
      output SI.Position normalPressureCentroid[2];
      output Boolean normalPressureCentroidValid;
      output SI.Torque freeMomentAtCOP;
      output SI.Torque yawFromShear;
      output SI.Torque yawFromFreeMoment;
      output SI.Torque yawTotal;
      output SI.Torque torsionalCapacity;
      output SI.Length torsionalEffectiveRadius;
      output Real torsionalUtilization;
    
    protected
      ContactPoint zone[nZones](
        each groundHeight=groundHeight,
        each kNormal=kNormal,
        each cNormal=cNormal,
        each mu=mu,
        each vSlip=vSlip);
    
      SI.Torque freeMomentWorld[nZones,3];
      GroundWrenchSensor wrench(nZones=nZones,contactPlaneHeight=groundHeight);
      TorsionalContactLaw torsion(
        nZones=nZones,
        torsionalFrictionFactor=torsionalFrictionFactor,
        omegaSlip=omegaTorsionSlip,mu=mu,patchRadius=patchRadius);
    
    equation
      connect(frame_torsion, torsion.frame_foot);
      torsion.rWorld = zonePositionWorld;
      torsion.normalForce = zoneNormalForce;
      torsion.tangentialForce = zoneForceWorld[:,1:2];
    
      for i in 1:nZones loop
        connect(plantarFrames[i], zone[i].frame_contact);
    
        zonePositionWorld[i,:] = zone[i].rWorld;
        zoneForceWorld[i,:] = zone[i].forceWorld;
        zoneNormalForce[i] = zone[i].normalForce;
        frictionUtilization[i] = zone[i].frictionUtilization;
        zoneActive[i] = zone[i].active;
    
        // The aggregate pure yaw moment is reported once to the wrench sensor.
        freeMomentWorld[i,:] = if i == 1 then {0,0,torsion.freeMoment} else {0,0,0};
      end for;
    
      wrench.rWorld = zonePositionWorld;
      wrench.forceWorld = zoneForceWorld;
      wrench.freeMomentWorld = freeMomentWorld;
    
      groundReactionForce = wrench.resultantForce;
      groundMoment = wrench.resultantMoment;
      cop = wrench.cop;
      copValid = wrench.copValid;
      freeMomentAtCOP = wrench.freeMomentAtCOP;
      normalPressureCentroid = torsion.normalCOP;
      normalPressureCentroidValid = torsion.normalCOPValid;
      yawFromShear = wrench.yawFromShear;
      yawFromFreeMoment = wrench.yawFromFreeMoment;
      yawTotal = wrench.yawTotal;
      torsionalCapacity = torsion.capacity;
      torsionalEffectiveRadius = torsion.effectiveRadius;
      torsionalUtilization = torsion.utilization;
    
      annotation(Documentation(info="<html><p>v0.7: six unilateral contact forces,
      a plane-aware wrench/COP sensor and optional residual-budget disk-patch spin.
      A normal-force centroid and a wrench-equivalent COP are both reported because
      penetration, shear and reporting-plane height can make them differ. The spin
      model no longer adds an independent whole-foot capacity on top of saturated
      shear. See docs/RELEASE_V0_7.md for scope and migration.</p></html>"));
    end PlantarContact;
  
    function torsionalCapacity
      "Derived torsional free-moment capacity from the current normal-load footprint"
      // LEGACY v0.5/v0.6 formula: retained for regression only; NOT used by v0.7 active contact.
      import SI = Modelica.Units.SI;
    
      input Integer nZones(min=1)=6;
      input SI.Position rWorld[nZones,3];
      input SI.Force normalForce[nZones];
      input Real torsionalFrictionFactor(min=0)=0
        "Dimensionless model coefficient; explicit assumption, not a human constant";
      input SI.Force fzEps=1e-9;
    
      output SI.Torque capacity;
      output SI.Length effectiveRadius;
      output SI.Position normalCOP[2];
    
    protected
      SI.Force totalNormal;
      Real secondMoment(unit="m2");
      Real weightedPosition[2](each unit="N.m") "First moment of compressive load";
    
    algorithm
      assert(fzEps>=0 and torsionalFrictionFactor>=0, "Nonnegative threshold/factor required.");
      totalNormal := 0;
      normalCOP := {0,0};
      weightedPosition := {0,0};
    
      for i in 1:nZones loop
        totalNormal := totalNormal + max(0, normalForce[i]);
        weightedPosition[1] := weightedPosition[1] + rWorld[i,1]*max(0, normalForce[i]);
        weightedPosition[2] := weightedPosition[2] + rWorld[i,2]*max(0, normalForce[i]);
      end for;
    
      if totalNormal > fzEps then
        normalCOP := weightedPosition/totalNormal;
        secondMoment := 0;
        for i in 1:nZones loop
          secondMoment := secondMoment
            + max(0, normalForce[i])
              *((rWorld[i,1]-normalCOP[1])^2
              + (rWorld[i,2]-normalCOP[2])^2)/totalNormal;
        end for;
        effectiveRadius := sqrt(max(0, secondMoment));
        capacity := torsionalFrictionFactor*totalNormal*effectiveRadius;
      else
        normalCOP := {0,0}; // Undefined COP: storage sentinel, not a support location.
        effectiveRadius := 0;
        capacity := 0;
      end if;
    
      annotation(Documentation(info="<html>
      <p><b>Project derivation, not a published constitutive law.</b> The current
      normal-load footprint is reduced to a load-weighted RMS radius about its
      normal-force COP:</p>
      <p>r_eff^2 = sum_i Fz_i ||r_i,xy-r_COP,xy||^2 / sum_i Fz_i.</p>
      <p>The diagnostic torsional capacity is then</p>
      <p>|Mz,free| &lt;= mu_t Fz r_eff.</p>
      <p>This construction is dimensionally consistent, becomes zero when contact
      collapses to a single point, increases with both normal load and support
      spread, and preserves the scientific distinction between COP migration and
      yaw-generating tangential/torsional contact. The factor mu_t is an explicit
      model parameter to be calibrated or swept; it is not identified as a human,
      shoe, or floor constant.</p>
      </html>"));
    end torsionalCapacity;
  
    model TorsionalContactLaw
      "Optional dissipative spin moment using residual local traction capacity (v0.7)"
      import SI = Modelica.Units.SI;
      parameter Integer nZones(min=1)=6;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0
        "Fraction of residual local Coulomb budget, NOT an independent friction coefficient";
      parameter Real mu(min=0)=0.7;
      parameter SI.Length patchRadius[nZones]=fill(0,nZones)
        "Explicit uniform circular patch radii; zero means no subpatch spin";
      parameter SI.AngularVelocity omegaSlip=0.05;
      input SI.Position rWorld[nZones,3];
      input SI.Force normalForce[nZones];
      input SI.Force tangentialForce[nZones,2];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_foot;
      output SI.Torque freeMoment;
      output SI.Torque capacity;
      output SI.Torque zoneCapacity[nZones];
      output SI.Torque zoneFreeMoment[nZones];
      output SI.Length effectiveRadius "Capacity/mu/Fz; not a whole-foot RMS footprint radius";
      output SI.Position normalCOP[2];
      output Boolean normalCOPValid;
      output SI.AngularVelocity omegaZ;
      output Real utilization;
    protected
      SI.Force totalNormal;
      Modelica.Mechanics.MultiBody.Sensors.AbsoluteAngularVelocity angularVelocity(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Forces.WorldTorque worldTorque(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world);
    equation
      assert(omegaSlip>0, "omegaSlip must be positive.");
      connect(frame_foot, angularVelocity.frame_a);
      connect(frame_foot, worldTorque.frame_b);
      (capacity,zoneCapacity) = residualSpinCapacity(nZones,normalForce,
        tangentialForce,mu,patchRadius,torsionalFrictionFactor);
      totalNormal = sum(normalForce);
      normalCOPValid = totalNormal>1e-9;
      normalCOP = if normalCOPValid then
        {sum(rWorld[:,1].*normalForce)/totalNormal,
         sum(rWorld[:,2].*normalForce)/totalNormal} else {0,0};
      effectiveRadius = if mu*totalNormal>1e-9 then capacity/(mu*totalNormal) else 0;
      omegaZ = angularVelocity.w[3];
      for i in 1:nZones loop
        zoneFreeMoment[i] = -zoneCapacity[i]*Modelica.Math.tanh(omegaZ/omegaSlip);
        for j in i+1:nZones loop
          assert(torsionalFrictionFactor<=0 or normalForce[i]<=0 or normalForce[j]<=0
            or sqrt((rWorld[i,1]-rWorld[j,1])^2+(rWorld[i,2]-rWorld[j,2])^2)
               >= patchRadius[i]+patchRadius[j],
            "Loaded spin subpatches overlap in the horizontal plane.");
        end for;
      end for;
      freeMoment = sum(zoneFreeMoment);
      worldTorque.torque = {0,0,freeMoment};
      utilization = if capacity>1e-12 then abs(freeMoment)/capacity else 0;
      annotation(Documentation(info="<html><p>v0.7 replaces the uncoupled whole-foot RMS
      envelope. Nonzero spin now requires explicitly declared patch radii and shares
      the existing shear budget. Default factor and radii are zero. This regularized
      sliding law has no static stick torque at zero angular speed. It is a reduced
      horizontal-plane contact assumption, not validated plantar/footwear mechanics.</p></html>"));
    end TorsionalContactLaw;
  
    function residualSpinCapacity
      "Conservative spin capacities of uniform circular subpatches sharing the Coulomb budget"
      import SI = Modelica.Units.SI;
      input Integer nZones(min=1);
      input SI.Force normalForce[nZones];
      input SI.Force tangentialForce[nZones,2];
      input Real mu(min=0);
      input SI.Length patchRadius[nZones];
      input Real reserveFraction(min=0,max=1)=1;
      output SI.Torque capacity;
      output SI.Torque zoneCapacity[nZones];
    protected
      SI.Force remaining;
    algorithm
      assert(mu>=0 and reserveFraction>=0 and reserveFraction<=1,
        "Invalid friction coefficient or spin reserve fraction.");
      capacity := 0;
      for i in 1:nZones loop
        assert(patchRadius[i]>=0, "Patch radii must be nonnegative.");
        remaining := max(0, mu*max(0,normalForce[i])
          - sqrt(tangentialForce[i,1]^2+tangentialForce[i,2]^2));
        zoneCapacity[i] := reserveFraction*(2.0/3.0)*patchRadius[i]*remaining;
        capacity := capacity + zoneCapacity[i];
      end for;
      annotation(Documentation(info="<html><p>New project derivation under explicit assumptions:
      disjoint uniform-pressure circular subpatches on a horizontal plane. The
      sufficient local inequality is |Ft_i| + |Mz_i|/(2*a_i/3) &lt;= mu*Fz_i.
      It follows by superposing constant translational traction and symmetric
      azimuthal traction and using the triangle inequality. This is conservative,
      not the exact combined friction limit surface or measured plantar mechanics.</p></html>"));
    end residualSpinCapacity;
  

    model AuditedPlantarContact
      "Six-zone plantar contact with regional support and energy-audit outputs"
      import SI = Modelica.Units.SI;
      extends PlantarContact(torsionalFrictionFactor=0,zone(each vEps=1e-9));
      output SI.Length penetration[nZones]={max(0,groundHeight-zonePositionWorld[i,3]) for i in 1:nZones};
      output SI.Velocity velocity[nZones,3]=der(zonePositionWorld);
      output SI.Energy storedEnergy=0.5*kNormal*sum(penetration.^2);
      output SI.Power normalLoss[nZones],frictionLoss[nZones];
      output SI.Power lossPower;
      output SI.Power powerToBody=sum(zoneForceWorld[i,:]*velocity[i,:] for i in 1:nZones);
      output SI.Power identityResidual=der(storedEnergy)+lossPower+powerToBody;
      output SI.Length loadedTangentialTravel[nZones](each start=0,each fixed=true);
      output SI.Force heelLoad=sum(zoneNormalForce[1:2]);
      output SI.Force midfootLoad=sum(zoneNormalForce[3:4]);
      output SI.Force forefootLoad=sum(zoneNormalForce[5:6]);
      output Boolean supportValid=sum(zoneNormalForce)>1;
      output Real heelShare=if supportValid then heelLoad/sum(zoneNormalForce) else 0;
      output Boolean broadSupport=supportValid and min({heelLoad,midfootLoad,forefootLoad})>0.1;
    equation
      for i in 1:nZones loop
        normalLoss[i]=(zoneNormalForce[i]-kNormal*penetration[i])*(if penetration[i]>0 then -velocity[i,3] else 0);
        frictionLoss[i]=-zoneForceWorld[i,1:2]*velocity[i,1:2];
        der(loadedTangentialTravel[i])=if zoneNormalForce[i]>0.1 then sqrt(sum(velocity[i,1:2].^2)) else 0;
      end for;
      lossPower=sum(normalLoss)+sum(frictionLoss);
      assert(lossPower>=-1e-7,"Audited plantar contact generated unexplained energy.");
      annotation(Documentation(info="<html><p>Audit wrapper around the six-zone plantar model. It exposes heel, midfoot and forefoot normal loads, a broad-support flag, loaded tangential travel, compliant contact storage and dissipative power. It is a numerical contact observer, not a plantar tissue-pressure model.</p></html>"));
    end AuditedPlantarContact;

  end Contact;

