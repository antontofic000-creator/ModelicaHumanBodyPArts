within;
package ModelicaHumanBodyPArtsArticle2
  "Distributed contact research branch; not a human-validated or released package"
  import SI=Modelica.Units.SI;
  import MB=Modelica.Mechanics.MultiBody;
  import HB=ModelicaHumanBodyPArts;
  model SelectableLumbar
    extends HB.Transmission.LumbarSpine3D;
    parameter Integer architecture=3;
  protected
    Modelica.Mechanics.Rotational.Components.Fixed lockFE if architecture<3;
    Modelica.Mechanics.Rotational.Components.Fixed lockLB if architecture<3;
    Modelica.Mechanics.Rotational.Components.Fixed lockAX if architecture==1;
  equation
    connect(lockFE.flange,flexExt.axis);
    connect(lockLB.flange,lateralBend.axis);
    connect(lockAX.flange,axialRotation.axis);
  end SelectableLumbar;
    model RegularizedContactPoint
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
        mu*normalForce*Modelica.Math.tanh(vTangentialReg/vSlip);
    
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
    end RegularizedContactPoint;
  
    model RegularizedPlantar
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
      RegularizedContactPoint zone[nZones](
        each groundHeight=groundHeight,
        each kNormal=kNormal,
        each cNormal=cNormal,
        each mu=mu,
        each vSlip=vSlip);
    
      SI.Torque freeMomentWorld[nZones,3];
      HB.Contact.GroundWrenchSensor wrench(nZones=nZones,contactPlaneHeight=groundHeight);
      HB.Contact.TorsionalContactLaw torsion(
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
    end RegularizedPlantar;
  
  model AuditedPlantar
    "Velocity-regularized compliant contact: finite creep measured, NOT exact stiction"
    extends RegularizedPlantar(zone(each vEps=1e-9));
    output SI.Length penetration[nZones]={max(0,groundHeight-zonePositionWorld[i,3]) for i in 1:nZones};
    output SI.Velocity velocity[nZones,3]=der(zonePositionWorld);
    output SI.Energy storedEnergy=0.5*kNormal*sum(penetration.^2);
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
    output SI.Power normalLoss[nZones],frictionLoss[nZones];
  equation
    assert(abs(torsionalFrictionFactor)<1e-14,"This energy wrapper currently accounts for point shear, not added disk spin");
    for i in 1:nZones loop
      normalLoss[i]=(zoneNormalForce[i]-kNormal*penetration[i])*(if penetration[i]>0 then -velocity[i,3] else 0);
      frictionLoss[i]=-zoneForceWorld[i,1:2]*velocity[i,1:2];
      der(loadedTangentialTravel[i])=if zoneNormalForce[i]>0.1 then sqrt(sum(velocity[i,1:2].^2)) else 0;
    end for;
    lossPower=sum(normalLoss)+sum(frictionLoss);
  end AuditedPlantar;
    model RoleBody
      "Bilateral transmission assembly with rigid pelvic ring, variable-impedance lumbar/hips and diagnostic knee/ankle joints"
      import SI=Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter SI.Length lumbosacralToHipVertical;
      parameter SI.Length shoulderWidth;
      parameter SI.Length shoulderHeight=0.75*thoraxProps.length;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Boolean rightStance=true;
      parameter Integer architecture=3;
      parameter Modelica.Units.SI.Acceleration gravity=9.81;
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter SI.Angle leftHipStart[3]=zeros(3),rightHipStart[3]=zeros(3);
      parameter SI.Angle leftKneeStart=0,rightKneeStart=0;
      parameter SI.Angle leftAnkleStart[2]=zeros(2),rightAnkleStart[2]=zeros(2);
      parameter SI.Angle lumbarStart[3]=zeros(3);
      parameter Boolean lumbarFixed[3]=fill(false,3);
      parameter SI.AngularVelocity lumbarWStart[3]=zeros(3);
      parameter Boolean lumbarWFixed[3]=fill(false,3);
      parameter SI.RotationalSpringConstant hipK[3]={0,0,0};
      parameter SI.RotationalDampingConstant hipC[3]={0,0,0};
      parameter SI.Angle hipNeutral[3]={0,0,0};
      parameter SI.RotationalSpringConstant kneeK=0;
      parameter SI.RotationalDampingConstant kneeC=0;
      parameter SI.RotationalSpringConstant ankleK[2]={0,0};
      parameter SI.RotationalDampingConstant ankleC[2]={0,0};
      parameter SI.RotationalSpringConstant lumbarK[3]={0,0,0};
      parameter SI.RotationalDampingConstant lumbarC[3]={0,0,0};
      parameter Boolean useVariableImpedance=false
        "If true, hip/lumbar scale commands are supplied through control connectors";
      Modelica.Blocks.Interfaces.RealInput leftHipControl[9] if useVariableImpedance;
      Modelica.Blocks.Interfaces.RealInput rightHipControl[9] if useVariableImpedance;
      Modelica.Blocks.Interfaces.RealInput lumbarControl[9] if useVariableImpedance;
      parameter SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6],rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference,rightFootReference;

      output SI.Mass representedMass;
      output SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output SI.AngularVelocity leftW[6],rightW[6],lumbarW[3];
      output SI.Force leftHipReactionForce[3],rightHipReactionForce[3],leftKneeReactionForce[3],rightKneeReactionForce[3],leftAnkleReactionForce[3],rightAnkleReactionForce[3],lumbosacralForce[3];
      output SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3],leftKneeReactionMoment[3],rightKneeReactionMoment[3],leftAnkleReactionMoment[3],rightAnkleReactionMoment[3],lumbosacralMoment[3];
      output SI.Torque leftHipTorque[3],rightHipTorque[3],leftAnkleTorque[2],rightAnkleTorque[2],lumbarTorque[3];
      output SI.Torque leftKneeTorque,rightKneeTorque;
      output SI.Power leftHipPower,rightHipPower,leftKneePower,rightKneePower,leftAnklePower,rightAnklePower,lumbarPower;
      output SI.Power totalStiffnessModulationPower;

      output SI.Force cutForcesWorld[7,3] "Left ankle,knee,hip; right ankle,knee,hip; lumbar";
      output SI.Torque cutMomentsWorld[7,3];
      output SI.Power powerIntoProximalCut[7],powerToDistalBody[7],cutPowerClosure[7];
      output SI.Position segmentCOMWorld[8,3] "Pelvis,trunk,left thigh/shank/foot,right thigh/shank/foot";
      output SI.Position representedCOMWorld[3];
      output SI.Velocity representedCOMVelocity[3];
      output SI.Acceleration representedCOMAcceleration[3];
      output SI.Angle pelvisYawWorld,thoraxYawWorld;
      output Boolean pelvisYawValid,thoraxYawValid;
      output SI.Position leftToeWorld[3]=leftFoot.frame_toe.r_0;
      output SI.Position rightToeWorld[3]=rightFoot.frame_toe.r_0;
      parameter SI.Angle restAngles[15]={-0.007051898347754103,-0.05616621149897582,-0.0408266154749981,0.005876581951724801,-0.003525949171034881,-0.115275665089173,0.5320759336827905,-0.2669810911015702,0.1301746337389886,0.6048192081043453,0.294847674871562,0.115275665089173,0,-0.007052196139056831,0};
      parameter SI.RotationalSpringConstant stiffness[15]={1000,1000,20,1200,2000,2000,25,20,4,20,10,10,1000,1000,20};
      parameter SI.RotationalDampingConstant damping[15]={60,60,2,60,100,100,1.5,2,1.5,1,1,1,50,50,1};
      input SI.Torque ankleActuation;
      input SI.Torque hipYawActuation;
      output SI.Position freeHipWorld[3]=if rightStance then leftHip.frame_a.r_0 else rightHip.frame_a.r_0;
      output SI.Position freeFootWorld[3]=if rightStance then leftFoot.frame_ankle.r_0 else rightFoot.frame_ankle.r_0;
      output SI.Position freeFootRelativePelvis[3]=Modelica.Mechanics.MultiBody.Frames.resolve2(
        pelvis.frame_lumbosacral.R,freeFootWorld-freeHipWorld);
      output SI.Length freeHipToFoot=sqrt(sum((freeFootWorld-freeHipWorld).^2));
      output SI.Length freeSoleHeight[6]={if rightStance then leftPlantarFrames[i].r_0[3] else rightPlantarFrames[i].r_0[3] for i in 1:6};
      output SI.Angle allQ[15]=cat(1,leftQ,rightQ,lumbarQ);
      output SI.AngularVelocity allW[15]=cat(1,leftW,rightW,lumbarW);
      output SI.Energy kineticEnergy,potentialEnergy,elasticEnergy,mechanicalEnergy;
      output SI.Power actuatorPower=ankleActuation*(if rightStance then rightW[5] else leftW[5])+hipYawActuation*(if rightStance then rightW[3] else leftW[3]);
      output SI.Power dissipationPower=sum(actualDamping.*allW.^2);
      output SI.RotationalSpringConstant actualStiffness[15]=stiffness.*cat(1,leftHipKScale,{1},ones(2),rightHipKScale,{1},ones(2),lumbarKScale);
      output SI.RotationalDampingConstant actualDamping[15]=damping.*cat(1,leftHipCScale,{1},ones(2),rightHipCScale,{1},ones(2),lumbarCScale);
      output SI.Position stanceHipWorld[3]=if rightStance then rightHip.frame_a.r_0 else leftHip.frame_a.r_0;
      output SI.Position stanceKneeWorld[3]=if rightStance then rightKnee.frame_a.r_0 else leftKnee.frame_a.r_0;
      output SI.Position stanceAnkleWorld[3]=if rightStance then rightFoot.frame_ankle.r_0 else leftFoot.frame_ankle.r_0;
      output SI.Angle stanceAxis=atan2(stanceHipWorld[1]-stanceAnkleWorld[1],stanceHipWorld[3]-stanceAnkleWorld[3]);
      output SI.Angle shankAxis=atan2(stanceKneeWorld[1]-stanceAnkleWorld[1],stanceKneeWorld[3]-stanceAnkleWorld[3]);
      output SI.AngularMomentum angularMomentumWorld[3];
      output SI.Torque gravityMomentWorld[3];
      SI.AngularMomentum segmentSpinWorld[8,3],orbitalMomentum[8,3];
      SI.Torque segmentGravityMoment[8,3];
    protected
      SI.AngularVelocity omegaLocal[8,3];
      SI.Velocity segmentVelocity[8,3]=der(segmentCOMWorld);
      parameter SI.Inertia tensors[8,3,3]=cat(1,
        {pelvicProps.I_CM},{thoraxProps.I_CM},
        {diagonal({thighProps.ISagittal,thighProps.ITransverse,thighProps.ILongitudinal})},
        {diagonal({shankProps.ISagittal,shankProps.ITransverse,shankProps.ILongitudinal})},
        {diagonal({footProps.ILongitudinal,footProps.ITransverse,footProps.ISagittal})},
        {diagonal({thighProps.ISagittal,thighProps.ITransverse,thighProps.ILongitudinal})},
        {diagonal({shankProps.ISagittal,shankProps.ITransverse,shankProps.ILongitudinal})},
        {diagonal({footProps.ILongitudinal,footProps.ITransverse,footProps.ISagittal})});
      Real pelvisForwardWorld[3],thoraxForwardWorld[3];
      parameter SI.Mass segmentMasses[8]={pelvicProps.mass,thoraxProps.mass,
        thighProps.mass,shankProps.mass,footProps.mass,thighProps.mass,shankProps.mass,footProps.mass};
      Real leftHipKScale[3],leftHipCScale[3],leftHipKRate[3];
      Real rightHipKScale[3],rightHipCScale[3],rightHipKRate[3];
      Real lumbarKScale[3],lumbarCScale[3],lumbarKRate[3];
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      ModelicaHumanBodyPArts.AxialBody.PelvicRing pelvis(props=pelvicProps,hipCenterDistance=profile.hipCenterDistance,lumbosacralToHipVertical=lumbosacralToHipVertical,animation=animation);
      SelectableLumbar lumbar(architecture=architecture,mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,w_start=lumbarWStart,w_fixed=lumbarWFixed,kBase=stiffness[13:15],cBase=damping[13:15],qNeutral=restAngles[13:15]);
      ModelicaHumanBodyPArts.AxialBody.Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
      ModelicaHumanBodyPArts.SupportInitiation.HipDrive leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=stiffness[1:3],cBase=damping[1:3],qNeutral=restAngles[1:3]);
      ModelicaHumanBodyPArts.SupportInitiation.HipDrive rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=stiffness[7:9],cBase=damping[7:9],qNeutral=restAngles[7:9]);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation),rightThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Transmission.Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=stiffness[4],cBase=damping[4],qNeutral=restAngles[4]);
      ModelicaHumanBodyPArts.Transmission.Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=stiffness[10],cBase=damping[10],qNeutral=restAngles[10]);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation),rightShank(props=shankProps,animation=animation);
      ModelicaHumanBodyPArts.SupportInitiation.AnkleDrive leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=stiffness[5:6],cBase=damping[5:6],qNeutral=restAngles[5:6]);
      ModelicaHumanBodyPArts.SupportInitiation.AnkleDrive rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=stiffness[11:12],cBase=damping[11:12],qNeutral=restAngles[11:12]);
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
      segmentSpinWorld[1,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,tensors[1,:,:]*omegaLocal[1,:]);
      segmentSpinWorld[2,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,tensors[2,:,:]*omegaLocal[2,:]);
      segmentSpinWorld[3,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(leftThigh.frame_proximal.R,tensors[3,:,:]*omegaLocal[3,:]);
      segmentSpinWorld[4,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(leftShank.frame_proximal.R,tensors[4,:,:]*omegaLocal[4,:]);
      segmentSpinWorld[5,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(leftFoot.frame_ankle.R,tensors[5,:,:]*omegaLocal[5,:]);
      segmentSpinWorld[6,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(rightThigh.frame_proximal.R,tensors[6,:,:]*omegaLocal[6,:]);
      segmentSpinWorld[7,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(rightShank.frame_proximal.R,tensors[7,:,:]*omegaLocal[7,:]);
      segmentSpinWorld[8,:]=Modelica.Mechanics.MultiBody.Frames.resolve1(rightFoot.frame_ankle.R,tensors[8,:,:]*omegaLocal[8,:]);
      for j in 1:3 loop
        angularMomentumWorld[j]=sum(orbitalMomentum[i,j]+segmentSpinWorld[i,j] for i in 1:8);
        gravityMomentWorld[j]=sum(segmentGravityMoment[i,j] for i in 1:8);
      end for;
      for i in 1:8 loop
        orbitalMomentum[i,:]=cross(segmentCOMWorld[i,:],segmentMasses[i]*segmentVelocity[i,:]);
        segmentGravityMoment[i,:]=cross(segmentCOMWorld[i,:],{0,0,-gravity*segmentMasses[i]});
      end for;
      leftAnkle.drive=if rightStance then zeros(2) else {ankleActuation,0};
      rightAnkle.drive=if rightStance then {ankleActuation,0} else zeros(2);
      leftHip.drive=if rightStance then zeros(3) else {0,0,hipYawActuation};
      rightHip.drive=if rightStance then {0,0,hipYawActuation} else zeros(3);
      omegaLocal[1,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(pelvis.frame_lumbosacral.R);
      omegaLocal[2,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(thorax.frame_lumbar.R);
      omegaLocal[3,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(leftThigh.frame_proximal.R);
      omegaLocal[4,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(leftShank.frame_proximal.R);
      omegaLocal[5,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(leftFoot.frame_ankle.R);
      omegaLocal[6,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(rightThigh.frame_proximal.R);
      omegaLocal[7,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(rightShank.frame_proximal.R);
      omegaLocal[8,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(rightFoot.frame_ankle.R);
      kineticEnergy=sum({0.5*segmentMasses[i]*sum(segmentVelocity[i,:].^2)
        +0.5*omegaLocal[i,:]*tensors[i,:,:]*omegaLocal[i,:] for i in 1:8});
      potentialEnergy=gravity*sum({segmentMasses[i]*segmentCOMWorld[i,3] for i in 1:8});
      elasticEnergy=0.5*sum(actualStiffness.*(allQ-restAngles).^2);
      mechanicalEnergy=kineticEnergy+potentialEnergy+elasticEnergy;
      cutForcesWorld[1,:]=leftAnkle.cutForceWorld;
      cutMomentsWorld[1,:]=leftAnkle.cutMomentWorld;
      powerIntoProximalCut[1]=leftAnkle.cutPowerIntoA;
      powerToDistalBody[1]=leftAnkle.powerToDistalBody;
      cutPowerClosure[1]=leftAnkle.cutPowerClosure;
      cutForcesWorld[2,:]=leftKnee.cutForceWorld;
      cutMomentsWorld[2,:]=leftKnee.cutMomentWorld;
      powerIntoProximalCut[2]=leftKnee.cutPowerIntoA;
      powerToDistalBody[2]=leftKnee.powerToDistalBody;
      cutPowerClosure[2]=leftKnee.cutPowerClosure;
      cutForcesWorld[3,:]=leftHip.cutForceWorld;
      cutMomentsWorld[3,:]=leftHip.cutMomentWorld;
      powerIntoProximalCut[3]=leftHip.cutPowerIntoA;
      powerToDistalBody[3]=leftHip.powerToDistalBody;
      cutPowerClosure[3]=leftHip.cutPowerClosure;
      cutForcesWorld[4,:]=rightAnkle.cutForceWorld;
      cutMomentsWorld[4,:]=rightAnkle.cutMomentWorld;
      powerIntoProximalCut[4]=rightAnkle.cutPowerIntoA;
      powerToDistalBody[4]=rightAnkle.powerToDistalBody;
      cutPowerClosure[4]=rightAnkle.cutPowerClosure;
      cutForcesWorld[5,:]=rightKnee.cutForceWorld;
      cutMomentsWorld[5,:]=rightKnee.cutMomentWorld;
      powerIntoProximalCut[5]=rightKnee.cutPowerIntoA;
      powerToDistalBody[5]=rightKnee.powerToDistalBody;
      cutPowerClosure[5]=rightKnee.cutPowerClosure;
      cutForcesWorld[6,:]=rightHip.cutForceWorld;
      cutMomentsWorld[6,:]=rightHip.cutMomentWorld;
      powerIntoProximalCut[6]=rightHip.cutPowerIntoA;
      powerToDistalBody[6]=rightHip.powerToDistalBody;
      cutPowerClosure[6]=rightHip.cutPowerClosure;
      cutForcesWorld[7,:]=lumbar.cutForceWorld;
      cutMomentsWorld[7,:]=lumbar.cutMomentWorld;
      powerIntoProximalCut[7]=lumbar.cutPowerIntoA;
      powerToDistalBody[7]=lumbar.powerToDistalBody;
      cutPowerClosure[7]=lumbar.cutPowerClosure;
      segmentCOMWorld[1,:]=pelvis.frame_lumbosacral.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,pelvicProps.rCM);
      segmentCOMWorld[2,:]=thorax.frame_lumbar.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,thoraxProps.rCM);
      segmentCOMWorld[3,:]=leftThigh.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftThigh.frame_proximal.R,{0,0,-thighProps.comDistance});
      segmentCOMWorld[4,:]=leftShank.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftShank.frame_proximal.R,{0,0,-shankProps.comDistance});
      segmentCOMWorld[5,:]=leftFoot.frame_ankle.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftFoot.frame_ankle.R,leftFoot.comPositionLocal);
      segmentCOMWorld[6,:]=rightThigh.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightThigh.frame_proximal.R,{0,0,-thighProps.comDistance});
      segmentCOMWorld[7,:]=rightShank.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightShank.frame_proximal.R,{0,0,-shankProps.comDistance});
      segmentCOMWorld[8,:]=rightFoot.frame_ankle.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightFoot.frame_ankle.R,rightFoot.comPositionLocal);
      for j in 1:3 loop
        representedCOMWorld[j]=sum({segmentMasses[i]*segmentCOMWorld[i,j] for i in 1:8})/representedMass;
      end for;
      representedCOMVelocity=der(representedCOMWorld);
      representedCOMAcceleration=der(representedCOMVelocity);
      pelvisForwardWorld=Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,{1,0,0});
      thoraxForwardWorld=Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,{1,0,0});
      pelvisYawValid=pelvisForwardWorld[1]^2+pelvisForwardWorld[2]^2>1e-12;
      thoraxYawValid=thoraxForwardWorld[1]^2+thoraxForwardWorld[2]^2>1e-12;
      pelvisYawWorld=atan2(pelvisForwardWorld[2],pelvisForwardWorld[1]);
      thoraxYawWorld=atan2(thoraxForwardWorld[2],thoraxForwardWorld[1]);
      connect(frame_pelvisReference,pelvis.frame_lumbosacral); connect(pelvis.frame_lumbosacral,lumbar.frame_pelvis); connect(lumbar.frame_thorax,thorax.frame_lumbar); connect(thorax.frame_cervical,frame_cervical);
      connect(pelvis.frame_leftHip,leftHip.frame_a); connect(leftHip.frame_b,leftThigh.frame_proximal); connect(leftThigh.frame_distal,leftKnee.frame_a); connect(leftKnee.frame_b,leftShank.frame_proximal); connect(leftShank.frame_distal,leftAnkle.frame_a); connect(leftAnkle.frame_b,leftFoot.frame_ankle); connect(leftFoot.frame_ankle,leftFootReference);
      connect(pelvis.frame_rightHip,rightHip.frame_a); connect(rightHip.frame_b,rightThigh.frame_proximal); connect(rightThigh.frame_distal,rightKnee.frame_a); connect(rightKnee.frame_b,rightShank.frame_proximal); connect(rightShank.frame_distal,rightAnkle.frame_a); connect(rightAnkle.frame_b,rightFoot.frame_ankle); connect(rightFoot.frame_ankle,rightFootReference);
      for i in 1:6 loop connect(leftFoot.frame_plantar[i],leftPlantarFrames[i]); connect(rightFoot.frame_plantar[i],rightPlantarFrames[i]); end for;
      if useVariableImpedance then
        leftHipKScale=leftHipControl[1:3]; leftHipCScale=leftHipControl[4:6]; leftHipKRate=leftHipControl[7:9];
        rightHipKScale=rightHipControl[1:3]; rightHipCScale=rightHipControl[4:6]; rightHipKRate=rightHipControl[7:9];
        lumbarKScale=lumbarControl[1:3]; lumbarCScale=lumbarControl[4:6]; lumbarKRate=lumbarControl[7:9];
      else
        leftHipKScale=fill(1,3); leftHipCScale=fill(1,3); leftHipKRate=zeros(3);
        rightHipKScale=fill(1,3); rightHipCScale=fill(1,3); rightHipKRate=zeros(3);
        lumbarKScale=fill(1,3); lumbarCScale=fill(1,3); lumbarKRate=zeros(3);
      end if;
      leftHip.stiffnessScale=leftHipKScale; leftHip.dampingScale=leftHipCScale; leftHip.stiffnessScaleRate=leftHipKRate;
      rightHip.stiffnessScale=rightHipKScale; rightHip.dampingScale=rightHipCScale; rightHip.stiffnessScaleRate=rightHipKRate;
      leftKnee.stiffnessScale=1; leftKnee.dampingScale=1; leftKnee.stiffnessScaleRate=0;
      rightKnee.stiffnessScale=1; rightKnee.dampingScale=1; rightKnee.stiffnessScaleRate=0;
      leftAnkle.stiffnessScale=fill(1,2); leftAnkle.dampingScale=fill(1,2); leftAnkle.stiffnessScaleRate=zeros(2);
      rightAnkle.stiffnessScale=fill(1,2); rightAnkle.dampingScale=fill(1,2); rightAnkle.stiffnessScaleRate=zeros(2);
      lumbar.stiffnessScale=lumbarKScale; lumbar.dampingScale=lumbarCScale; lumbar.stiffnessScaleRate=lumbarKRate;
      leftQ=cat(1,leftHip.q,{leftKnee.q},leftAnkle.q); rightQ=cat(1,rightHip.q,{rightKnee.q},rightAnkle.q); lumbarQ=lumbar.q;
      leftW=cat(1,leftHip.w,{leftKnee.w},leftAnkle.w); rightW=cat(1,rightHip.w,{rightKnee.w},rightAnkle.w); lumbarW=lumbar.w;
      representedMass=pelvicProps.mass+thoraxProps.mass+2*(thighProps.mass+shankProps.mass+footProps.mass);
      leftHipReactionForce=leftHip.reactionForce; rightHipReactionForce=rightHip.reactionForce; leftKneeReactionForce=leftKnee.reactionForce; rightKneeReactionForce=rightKnee.reactionForce; leftAnkleReactionForce=leftAnkle.reactionForce; rightAnkleReactionForce=rightAnkle.reactionForce; lumbosacralForce=lumbar.reactionForce;
      leftHipReactionMoment=leftHip.reactionMoment; rightHipReactionMoment=rightHip.reactionMoment; leftKneeReactionMoment=leftKnee.reactionMoment; rightKneeReactionMoment=rightKnee.reactionMoment; leftAnkleReactionMoment=leftAnkle.reactionMoment; rightAnkleReactionMoment=rightAnkle.reactionMoment; lumbosacralMoment=lumbar.reactionMoment;
      leftHipTorque=leftHip.generalizedTorque; rightHipTorque=rightHip.generalizedTorque; leftKneeTorque=leftKnee.generalizedTorque; rightKneeTorque=rightKnee.generalizedTorque; leftAnkleTorque=leftAnkle.generalizedTorque; rightAnkleTorque=rightAnkle.generalizedTorque; lumbarTorque=lumbar.generalizedTorque;
      leftHipPower=leftHip.generalizedPower; rightHipPower=rightHip.generalizedPower; leftKneePower=leftKnee.generalizedPower; rightKneePower=rightKnee.generalizedPower; leftAnklePower=leftAnkle.generalizedPower; rightAnklePower=rightAnkle.generalizedPower; lumbarPower=lumbar.generalizedPower;
      totalStiffnessModulationPower=leftHip.stiffnessModulationPower+rightHip.stiffnessModulationPower+leftKnee.stiffnessModulationPower+rightKnee.stiffnessModulationPower+leftAnkle.stiffnessModulationPower+rightAnkle.stiffnessModulationPower+lumbar.stiffnessModulationPower;
      annotation(Documentation(info="<html><p>This v0.9.1 assembly exposes cut reaction wrenches at ankle, knee, hip and lumbosacral interfaces and generalized torque/power for the explicit impedance coordinates. It still does not identify individual muscles or cartilage contact stress.</p></html>"));
    end RoleBody;

  model DistributedSupport
    "Free-root bilateral body, two actual plantar contacts, passive free leg"
    parameter Boolean rightStance=true;
    parameter Integer architecture=3;
    parameter Real ankleAmplitude=15,hipAmplitude=4;
    parameter Real normalStiffness=2e5,normalDamping=500,friction=0.6,slipVelocity=1e-4;
    parameter Real onset=0.25,rise=0.10,hold=0.10,fall=0.10;
    parameter Integer impedanceMode=0 "0 fixed; 1 reduce k; 2 reduce c; 3 reduce both";
    parameter Real releaseOnset=0.30,releaseDuration=0.40,releaseScale=0.6;
    parameter Boolean releaseFreeHip=true "Apply the impedance schedule to the free-side hip";
    parameter Boolean releaseStanceHip=true "Apply the impedance schedule to the standing-side hip";
    parameter Boolean releaseLumbar=true "Apply the impedance schedule to the lumbar coordinates";
    parameter Real endTime=2.0;
    parameter Boolean useQuaternionRoot=true;
    parameter SI.Length initialRootZ=0.07924886405921136;
    parameter SI.Angle initialRootAngles[3]={0,-0.00432627310134715,0};
    inner MB.World world(n={0,0,-1},g=9.81,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,
        pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_M2B_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,
        rCM={0,0,-0.05},I_CM={{0.1,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_M2B_PELVIS");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.5,
        rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_M2B_UPPER_TRUNK");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,
        qMin={-0.5,-0.7,-0.7},qMax={2.2,0.7,0.7},sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,
        qMin={-0.15},qMax={2.8},sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,
        qMin={-0.8,-0.6},qMax={0.8,0.6},sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,
        qMin=fill(-0.5,3),qMax=fill(0.5,3),sourceId="SYNTHETIC_M2B_ROM_GATE");
    parameter SI.Angle stanceQ0[6]={0,0,0,0,0,-0.115275665089173};
    parameter SI.Angle freeQ0[6]={0.25,0,0,0.5,0.25,0.115275665089173};
    parameter SI.Angle q0[15]=if rightStance then cat(1,freeQ0,stanceQ0,zeros(3)) else cat(1,stanceQ0,freeQ0,zeros(3));
    parameter Real stanceK[6]={1000,1000,20,1200,2000,2000};
    parameter Real freeK[6]={25,20,4,20,10,10};
    parameter Real stanceC[6]={60,60,2,60,100,100};
    parameter Real freeC[6]={1.5,2,1.5,1,1,1};
    parameter Real springK[15]=if rightStance then cat(1,freeK,stanceK,{1000,1000,20}) else cat(1,stanceK,freeK,{1000,1000,20});
    parameter Real damperC[15]=if rightStance then cat(1,freeC,stanceC,{50,50,1}) else cat(1,stanceC,freeC,{50,50,1});
    parameter SI.Angle freeRestOffset[6]={0.2901288933033483,-0.2669813846837966,0.13011874143227378,0.1025504775721728,0.0450421873714625,0}
      "Pilot rest-angle offset inherited from the solved reference posture; explicit modeling assumption";
    parameter SI.Angle stanceRest[6]={-0.00686489078097669,-0.056165685873747685,-0.027513290159981284,0.004877833374132738,-0.0023761573712654622,-0.11527566508913786};
    parameter SI.Angle equilibriumRest[15]=if rightStance then cat(1,freeQ0+freeRestOffset,stanceRest,{0.0002652537920812973,0.007052130144313213,0}) else cat(1,stanceRest,freeQ0+freeRestOffset,{0.0002652537920812973,-0.007052130144313213,0})
      "Reference posture reproduces old solved rest values exactly; changed freeQ0 preserves the old rest offset as a pilot assumption";
    RoleBody body(profile=profile,pelvicProps=pp,thoraxProps=tp,rightStance=rightStance,
      architecture=architecture,lumbosacralToHipVertical=0.1,shoulderWidth=0.4,
      footCOMAboveSole=0.035,footCOMOffsetSourceId="SYNTHETIC_M2B_OFFSET",
      hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,
      leftHipStart=q0[1:3],leftKneeStart=q0[4],leftAnkleStart=q0[5:6],
      rightHipStart=q0[7:9],rightKneeStart=q0[10],rightAnkleStart=q0[11:12],
      lumbarStart=q0[13:15],fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
      lumbarFixed={architecture==3,architecture==3,architecture>1},
      lumbarWFixed={architecture==3,architecture==3,architecture>1},
      restAngles=equilibriumRest,stiffness=springK,damping=damperC,useVariableImpedance=true,animation=false);
    MB.Joints.FreeMotion root(animation=false,useQuaternions=useQuaternionRoot,
      r_rel_a(start={0,0,initialRootZ},each fixed=true),
      v_rel_a(start=zeros(3),each fixed=true),angles_fixed=true,
      angles_start=initialRootAngles,w_rel_a_fixed=true,w_rel_a_start=zeros(3));
    AuditedPlantar oldContact(kNormal=normalStiffness,cNormal=normalDamping,mu=friction,vSlip=slipVelocity);
    AuditedPlantar newContact(kNormal=normalStiffness,cNormal=normalDamping,mu=friction,vSlip=slipVelocity);
    HB.SupportInitiation.SmoothSupportPulse pulse(onset=onset,rise=rise,hold=hold,fall=fall);
    output SI.Force groundForce[3]=oldContact.groundReactionForce+newContact.groundReactionForce;
    output SI.Torque groundMoment[3]=oldContact.groundMoment+newContact.groundMoment;
    output SI.Force forceResidual[3]=groundForce+{0,0,-9.81*body.representedMass}-body.representedMass*body.representedCOMAcceleration;
    output SI.Torque momentResidual[3]=groundMoment+body.gravityMomentWorld-der(body.angularMomentumWorld);
    output SI.AngularVelocity footOmega[3]=MB.Frames.angularVelocity1(root.frame_b.R);
    output Real footForward[3]=MB.Frames.resolve1(root.frame_b.R,{1,0,0});
    output SI.Angle footYaw=atan2(footForward[2],footForward[1]);
    output SI.Energy storedEnergy=body.mechanicalEnergy+oldContact.storedEnergy+newContact.storedEnergy;
    output SI.Energy activeWork(start=0,fixed=true),dissipatedEnergy(start=0,fixed=true),modulationWorkToMechanical(start=0,fixed=true);
    output SI.Energy energyResidual=storedEnergy-initialEnergy+dissipatedEnergy-activeWork+modulationWorkToMechanical;
    output SI.Position freeDeltaWorld[3]=body.freeFootWorld-freeInitial;
    output SI.Position freeDeltaHip[3]=body.freeFootRelativePelvis-freeRelativeInitial;
    output SI.Length freeLengthChange=body.freeHipToFoot-initialLength;
    output SI.Position forwardHip=body.stanceHipWorld[1]-body.stanceAnkleWorld[1];
    output SI.Position forwardKnee=body.stanceKneeWorld[1]-body.stanceAnkleWorld[1];
    output SI.Angle stanceAxis=body.stanceAxis,shankAxis=body.shankAxis;
    output Real newSupportShare=if groundForce[3]>1 then newContact.groundReactionForce[3]/groundForce[3] else 0;
    output Boolean supportValid=groundForce[3]>1;
    output SI.Force heelLoad=oldContact.heelLoad,forefootLoad=oldContact.forefootLoad;
    output Real heelShare=oldContact.heelShare;
    output SI.Length heelGap=noEvent(min({oldContact.zonePositionWorld[1,3],oldContact.zonePositionWorld[2,3]}));
    output Boolean heelRetained=oldContact.supportValid and heelLoad>0.1 and heelGap<=1e-5;
    output SI.Length freeClearance=noEvent(min(newContact.zonePositionWorld[:,3]));
    output SI.Length stanceSlip=noEvent(max(oldContact.loadedTangentialTravel));
    output SI.Angle pelvisYaw=body.pelvisYawWorld,lumbarYaw=body.lumbarQ[3],thoraxYaw=body.thoraxYawWorld;
    output SI.Angle freeJointQ[6]=if rightStance then body.leftQ else body.rightQ;
    output SI.Time firstTouch(start=-1,fixed=true),firstLoad(start=-1,fixed=true),halfTransfer(start=-1,fixed=true);
    output Real coefficientScale;
    output SI.Torque commandAnkle=body.ankleActuation,commandHipYaw=body.hipYawActuation;
    output SI.Torque directFreeLegCommand=0 "All active free-leg drives are zero in this branch";
    output SI.Force oldNormal=oldContact.groundReactionForce[3],newNormal=newContact.groundReactionForce[3];
    output SI.Force midfootLoad=oldContact.midfootLoad;
    output Real heelBodyWeight=heelLoad/(body.representedMass*world.g);
    output Boolean heelFractionValid=oldContact.supportValid;
    output Boolean broadSupport=oldContact.broadSupport;
    output SI.Position freeToeWorld[3]=if rightStance then body.leftToeWorld else body.rightToeWorld;
    output SI.Position stanceAnkleWorld[3]=body.stanceAnkleWorld,stanceKneeWorld[3]=body.stanceKneeWorld,stanceHipWorld[3]=body.stanceHipWorld;
    output SI.Position freeAnkleWorld[3]=body.freeFootWorld,freeHipWorld[3]=body.freeHipWorld;
    output SI.Position forwardHipFoot=(footForward[1]*(stanceHipWorld[1]-stanceAnkleWorld[1])+footForward[2]*(stanceHipWorld[2]-stanceAnkleWorld[2]))/sqrt(footForward[1]^2+footForward[2]^2);
    output SI.Position copFootX=(footForward[1]*(oldContact.cop[1]-stanceAnkleWorld[1])+footForward[2]*(oldContact.cop[2]-stanceAnkleWorld[2]))/sqrt(footForward[1]^2+footForward[2]^2);
    output SI.Angle jointLowerMargins[15]=body.allQ-cat(1,hipROM.qMin,kneeROM.qMin,ankleROM.qMin,hipROM.qMin,kneeROM.qMin,ankleROM.qMin,lumbarROM.qMin);
    output SI.Angle jointUpperMargins[15]=cat(1,hipROM.qMax,kneeROM.qMax,ankleROM.qMax,hipROM.qMax,kneeROM.qMax,ankleROM.qMax,lumbarROM.qMax)-body.allQ;
    output SI.Angle minimumROMMargin=noEvent(min(cat(1,jointLowerMargins,jointUpperMargins)));
    output SI.Power contactIdentityResidual=oldContact.identityResidual+newContact.identityResidual;
    output Integer checksPassed(start=0,fixed=true);
  protected
    parameter SI.Energy initialEnergy(fixed=false);
    parameter SI.Position freeInitial[3](each fixed=false),freeRelativeInitial[3](each fixed=false);
    parameter SI.Length initialLength(fixed=false);
    Real releaseShape,releaseRate;
    Boolean leftHipRelease,rightHipRelease;
  initial equation
    initialEnergy=storedEnergy;
    freeInitial=body.freeFootWorld;freeRelativeInitial=body.freeFootRelativePelvis;initialLength=body.freeHipToFoot;
  equation
    connect(world.frame_b,root.frame_a);
    if rightStance then
      connect(root.frame_b,body.rightFootReference);
      connect(body.rightFootReference,oldContact.frame_torsion);
      connect(body.leftFootReference,newContact.frame_torsion);
      for i in 1:6 loop
        connect(body.rightPlantarFrames[i],oldContact.plantarFrames[i]);
        connect(body.leftPlantarFrames[i],newContact.plantarFrames[i]);
      end for;
    else
      connect(root.frame_b,body.leftFootReference);
      connect(body.leftFootReference,oldContact.frame_torsion);
      connect(body.rightFootReference,newContact.frame_torsion);
      for i in 1:6 loop
        connect(body.leftPlantarFrames[i],oldContact.plantarFrames[i]);
        connect(body.rightPlantarFrames[i],newContact.plantarFrames[i]);
      end for;
    end if;
    body.ankleActuation=ankleAmplitude*pulse.y;
    body.hipYawActuation=hipAmplitude*pulse.y;
    releaseShape=HB.SupportInitiation.unitStep5((time-releaseOnset)/releaseDuration);
    releaseRate=der(releaseShape);
    coefficientScale=1-(1-releaseScale)*releaseShape;
    leftHipRelease=if rightStance then releaseFreeHip else releaseStanceHip;
    rightHipRelease=if rightStance then releaseStanceHip else releaseFreeHip;
    body.leftHipControl=cat(1,fill(if leftHipRelease and (impedanceMode==1 or impedanceMode==3) then coefficientScale else 1,3),
      fill(if leftHipRelease and (impedanceMode==2 or impedanceMode==3) then coefficientScale else 1,3),
      fill(if leftHipRelease and (impedanceMode==1 or impedanceMode==3) then -(1-releaseScale)*releaseRate else 0,3));
    body.rightHipControl=cat(1,fill(if rightHipRelease and (impedanceMode==1 or impedanceMode==3) then coefficientScale else 1,3),
      fill(if rightHipRelease and (impedanceMode==2 or impedanceMode==3) then coefficientScale else 1,3),
      fill(if rightHipRelease and (impedanceMode==1 or impedanceMode==3) then -(1-releaseScale)*releaseRate else 0,3));
    body.lumbarControl=cat(1,fill(if releaseLumbar and (impedanceMode==1 or impedanceMode==3) then coefficientScale else 1,3),
      fill(if releaseLumbar and (impedanceMode==2 or impedanceMode==3) then coefficientScale else 1,3),
      fill(if releaseLumbar and (impedanceMode==1 or impedanceMode==3) then -(1-releaseScale)*releaseRate else 0,3));
    der(activeWork)=body.actuatorPower;
    der(modulationWorkToMechanical)=body.totalStiffnessModulationPower;
    der(dissipatedEnergy)=body.dissipationPower+oldContact.lossPower+newContact.lossPower;
    assert(max(abs(root.frame_b.f))<1e-10 and max(abs(root.frame_b.t))<1e-10,"Support bypass detected");
    assert(oldContact.lossPower>-1e-7 and newContact.lossPower>-1e-7,"Contact generated unexplained energy");
  algorithm
    when freeClearance<=0 then
      if pre(firstTouch)<0 then firstTouch:=time;end if;
    end when;
    when newContact.groundReactionForce[3]>1 then
      if pre(firstLoad)<0 then firstLoad:=time;end if;
    end when;
    when newSupportShare>=0.5 then
      if pre(halfTransfer)<0 then halfTransfer:=time;end if;
    end when;
    when time>=endTime-0.001 then
      assert(max(abs(forceResidual))<1e-3,"Force balance failed");
      assert(abs(energyResidual)<0.01,"Energy ledger failed");
      checksPassed:=1;
    end when;
    annotation(experiment(StopTime=2,Tolerance=1e-8));
  end DistributedSupport;
  model RightBaseline
    extends DistributedSupport(ankleAmplitude=0,hipAmplitude=0);
  end RightBaseline;
  model LeftBaseline
    extends RightBaseline(rightStance=false);
  end LeftBaseline;
  model RightCombined
    extends DistributedSupport;
  end RightCombined;
  model LeftCombined
    extends DistributedSupport(rightStance=false);
  end LeftCombined;
  package Nominal
    package Right
      model Locked
        extends DistributedSupport(
          rightStance=true,architecture=1,ankleAmplitude=15,hipAmplitude=-1,
          hold=0.6,fall=0.2,impedanceMode=0,
          freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
        annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
      end Locked;
      model YawOnly
        extends DistributedSupport(
          rightStance=true,architecture=2,ankleAmplitude=15,hipAmplitude=-1,
          hold=0.6,fall=0.2,impedanceMode=0,
          freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
        annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
      end YawOnly;
      model Full3D
        extends DistributedSupport(
          rightStance=true,architecture=3,ankleAmplitude=15,hipAmplitude=-1,
          hold=0.6,fall=0.2,impedanceMode=0,
          freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
        annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
      end Full3D;
    end Right;

    package Left
      model Locked
        extends DistributedSupport(
          rightStance=false,architecture=1,ankleAmplitude=15,hipAmplitude=-1,
          hold=0.6,fall=0.2,impedanceMode=0,
          freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
        annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
      end Locked;
      model YawOnly
        extends DistributedSupport(
          rightStance=false,architecture=2,ankleAmplitude=15,hipAmplitude=-1,
          hold=0.6,fall=0.2,impedanceMode=0,
          freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
        annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
      end YawOnly;
      model Full3D
        extends DistributedSupport(
          rightStance=false,architecture=3,ankleAmplitude=15,hipAmplitude=-1,
          hold=0.6,fall=0.2,impedanceMode=0,
          freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
        annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
      end Full3D;
    end Left;
  end Nominal;

  package Campaigns
    model RobustnessCase
      parameter Integer studyArchitecture(min=1,max=3)=2;
      parameter Real studyAnkleAmplitude=15;
      parameter Real studyHipAmplitude=-1;
      parameter Real studyFriction=0.6;
      parameter Real studyNormalStiffness(unit="N/m")=2e5;
      parameter SI.Angle studyFreeAnkle=-0.03;
      extends DistributedSupport(
        rightStance=true,
        architecture=studyArchitecture,
        ankleAmplitude=studyAnkleAmplitude,
        hipAmplitude=studyHipAmplitude,
        friction=studyFriction,
        normalStiffness=studyNormalStiffness,
        hold=0.6,fall=0.2,impedanceMode=0,
        freeQ0={0.25,0,0,0.5,studyFreeAnkle,0.115275665089173},
        endTime=1.5);
      annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
    end RobustnessCase;

    model LumbarSensitivityYawOnly
      parameter Real kTrans=1000;
      parameter Real cTrans=50;
      parameter Real kAx=20;
      parameter Real cAx=1;
      extends DistributedSupport(
        rightStance=true,architecture=2,ankleAmplitude=15,hipAmplitude=-1,
        hold=0.6,fall=0.2,impedanceMode=0,
        freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},
        springK={25,20,4,20,10,10,1000,1000,20,1200,2000,2000,kTrans,kTrans,kAx},
        damperC={1.5,2,1.5,1,1,1,60,60,2,60,100,100,cTrans,cTrans,cAx},
        endTime=1.5);
      annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
    end LumbarSensitivityYawOnly;

    model LumbarSensitivityFull3D
      extends LumbarSensitivityYawOnly(architecture=3);
    end LumbarSensitivityFull3D;
  end Campaigns;

  package Benchmark
    model TwoInertia
      import SI=Modelica.Units.SI;
      parameter SI.Inertia I1=1.2;
      parameter SI.Inertia I2=0.8;
      parameter SI.RotationalSpringConstant k=15;
      parameter SI.Angle delta0=0.10;
      parameter SI.AngularVelocity omega=sqrt(k*(1/I1+1/I2));
      SI.Angle q1(start=I2/(I1+I2)*delta0,fixed=true);
      SI.Angle q2(start=-I1/(I1+I2)*delta0,fixed=true);
      SI.AngularVelocity w1(start=0,fixed=true),w2(start=0,fixed=true);
      output SI.Angle delta=q1-q2;
      output SI.Angle analyticDelta=delta0*cos(omega*time);
      output SI.Angle deltaError=delta-analyticDelta;
      output Integer checksPassed(start=0,fixed=true);
    equation
      der(q1)=w1; der(q2)=w2;
      I1*der(w1)=-k*(q1-q2);
      I2*der(w2)= k*(q1-q2);
    algorithm
      when time>=0.999 then
        assert(abs(deltaError)<2e-6,"Two-inertia analytical benchmark failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-10,Interval=0.0005));
    end TwoInertia;
  end Benchmark;

  annotation(
    uses(Modelica(version="4.1.0"),ModelicaHumanBodyPArts(version="0.10.0")),
    Documentation(info="<html><p>Public convenience package for reproducing the Article 2 nominal models and parameterized campaigns with ModelicaHumanBodyPArts v0.10.0. The exact raw execution archive and hashes remain the publication record.</p></html>"));
end ModelicaHumanBodyPArtsArticle2;
