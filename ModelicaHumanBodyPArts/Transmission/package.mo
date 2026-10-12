within ModelicaHumanBodyPArts;
  package Transmission
    "Mechanical transmission, variable impedance and load-exposure diagnostics"
    extends Modelica.Icons.Package;

    model VariableImpedance1D
      "Variable rotational impedance with an explicit modulation-energy port"
      import SI = Modelica.Units.SI;
      extends Modelica.Mechanics.Rotational.Interfaces.PartialCompliantWithRelativeStates;
      parameter SI.RotationalSpringConstant kBase(min=0)=0;
      parameter SI.RotationalDampingConstant cBase(min=0)=0;
      parameter SI.Angle qNeutral=0 "Constant neutral joint angle; q=-phi_rel";
      parameter Real rateTolerance(unit="1/s")=1e-7;
      input Real stiffnessScale(min=0);
      input Real dampingScale(min=0);
      input Real stiffnessScaleRate(unit="1/s");
      output SI.Torque restoringTorque;
      output SI.Energy elasticEnergy;
      output SI.Power mechanicalPowerIntoElement;
      output SI.Power dampingDissipationPower;
      output SI.Power modulationPowerIntoStorage
        "Positive when modulation adds elastic storage at fixed deformation";
      output SI.Power stiffnessModulationPowerToMechanical
        "Legacy opposite-sign alias; NOT extra torque-times-speed joint power";
      output SI.Power energyBalanceResidual;
      output Real scaleRateResidual(unit="1/s");
    protected
      SI.Angle q;
      SI.AngularVelocity qd;
    equation
      assert(kBase>=0 and cBase>=0 and stiffnessScale>=0 and dampingScale>=0,
        "Impedance coefficients must be nonnegative.");
      q=-phi_rel;
      qd=-w_rel;
      tau=-kBase*stiffnessScale*(q-qNeutral)-cBase*dampingScale*qd;
      restoringTorque=tau;
      elasticEnergy=0.5*kBase*stiffnessScale*(q-qNeutral)^2;
      mechanicalPowerIntoElement=tau*w_rel;
      dampingDissipationPower=cBase*dampingScale*qd^2;
      modulationPowerIntoStorage=0.5*kBase*der(stiffnessScale)*(q-qNeutral)^2;
      stiffnessModulationPowerToMechanical=-modulationPowerIntoStorage;
      scaleRateResidual=stiffnessScaleRate-der(stiffnessScale);
      assert(noEvent(abs(scaleRateResidual)<=rateTolerance*(1+abs(stiffnessScaleRate))),
        "Supplied stiffnessScaleRate disagrees with the actual schedule derivative.");
      energyBalanceResidual=der(elasticEnergy)-mechanicalPowerIntoElement
        +dampingDissipationPower-modulationPowerIntoStorage;
      annotation(Documentation(info="<html><p>New engineering derivation: Udot = Pin - D + Pmod. Modulation is a separate energy exchange; a positive spring-return power is not a violation of passivity. Neutral position is constant. This is not a physiological breathing or muscle model. Continuous differentiable schedules are required.</p></html>"));
    end VariableImpedance1D;

    block SmoothImpedanceSchedule
      "Smooth preparation then release schedule; mechanical surrogate, not respiratory physiology"
      parameter Modelica.Units.SI.Time preparationEnd=0.05;
      parameter Modelica.Units.SI.Time releaseEnd=0.25;
      parameter Real initialScale(min=0)=1;
      parameter Real preparationScale(min=0)=1.2;
      parameter Real releaseScale(min=0)=0.45;
      output Real scale;
      output Real scaleRate(unit="1/s");
    protected
      Real u;
      Real s;
      Real dsdu;
    equation
      assert(preparationEnd>0 and releaseEnd>preparationEnd,"Require 0 < preparationEnd < releaseEnd");
      if time < preparationEnd then
        u=time/preparationEnd;
        s=10*u^3-15*u^4+6*u^5;
        dsdu=30*u^2-60*u^3+30*u^4;
        scale=initialScale+(preparationScale-initialScale)*s;
        scaleRate=(preparationScale-initialScale)*dsdu/preparationEnd;
      elseif time < releaseEnd then
        u=(time-preparationEnd)/(releaseEnd-preparationEnd);
        s=10*u^3-15*u^4+6*u^5;
        dsdu=30*u^2-60*u^3+30*u^4;
        scale=preparationScale+(releaseScale-preparationScale)*s;
        scaleRate=(releaseScale-preparationScale)*dsdu/(releaseEnd-preparationEnd);
      else
        u=1;
        s=1;
        dsdu=0;
        scale=releaseScale;
        scaleRate=0;
      end if;
      annotation(Documentation(info="<html><p>The schedule is deliberately generic. In Lynkorr studies it may be used as a breathing-linked impedance surrogate, but it does not model diaphragm motion, intra-abdominal pressure, EMG, muscle activation or respiratory gas mechanics.</p></html>"));
    end SmoothImpedanceSchedule;

    model InterfaceLoadMetrics
      "Wrench magnitudes, generalized power and convention-dependent load-exposure diagnostics"
      import SI = Modelica.Units.SI;
      parameter Integer n(min=1)=1;
      parameter SI.Mass declaredBodyMass(min=Modelica.Constants.small)=75;
      input SI.Mass representedMass(min=Modelica.Constants.small)=declaredBodyMass;
      parameter SI.Acceleration g=9.81;
      parameter SI.Force forceRegularization=1e-9;
      parameter SI.Torque momentRegularization=1e-9;
      parameter SI.AngularVelocity omegaEps=1e-3;
      input SI.Force force[3];
      input SI.Torque moment[3];
      input SI.Torque generalizedTorque[n];
      input SI.AngularVelocity generalizedSpeed[n];
      output SI.Force forceNorm;
      output Real forcePerDeclaredBW;
      output Real forcePerRepresentedWeight;
      output SI.Torque momentNorm;
      output SI.Power generalizedPower;
      output SI.AngularVelocity speedNorm;
      output Real highLoadLowMotionRatio(unit="N.m.s/rad");
      output Real forceLoadingRate(unit="N/s");
      output Real momentLoadingRate(unit="N.m/s");
      output Real forceImpulse(unit="N.s",start=0,fixed=true);
      output Real momentImpulse(unit="N.m.s",start=0,fixed=true);
      output Real forceVectorIntegral[3](each unit="N.s",each start=0,each fixed=true)
        "Vector impulse only when force components use one fixed reporting frame";
      output Real momentVectorIntegral[3](each unit="N.m.s",each start=0,each fixed=true)
        "Angular impulse only for a fixed reference point and frame";
      output SI.Energy positiveWork(start=0,fixed=true);
      output SI.Energy negativeWork(start=0,fixed=true)
        "Negative generalized work magnitude; includes possible elastic storage, not just heat";
    equation
      forceNorm=sqrt(sum(force.^2)+forceRegularization^2)-forceRegularization;
      momentNorm=sqrt(sum(moment.^2)+momentRegularization^2)-momentRegularization;
      forcePerDeclaredBW=forceNorm/(declaredBodyMass*g);
      forcePerRepresentedWeight=forceNorm/(representedMass*g);
      generalizedPower=sum(generalizedTorque.*generalizedSpeed);
      speedNorm=sqrt(sum(generalizedSpeed.^2));
      highLoadLowMotionRatio=momentNorm/(speedNorm+omegaEps);
      forceLoadingRate=der(forceNorm);
      momentLoadingRate=der(momentNorm);
      assert(declaredBodyMass>0 and representedMass>0 and g>0 and omegaEps>0,
        "Normalization masses, g and speed regularizer must be positive.");
      der(forceVectorIntegral)=force;
      der(momentVectorIntegral)=moment;
      der(forceImpulse)=forceNorm;
      der(momentImpulse)=momentNorm;
      der(positiveWork)=max(generalizedPower,0);
      der(negativeWork)=max(-generalizedPower,0);
      annotation(Documentation(info="<html><p>The highLoadLowMotionRatio is an engineering diagnostic only. It is not a validated biological blocking index, injury predictor or cartilage-stress measure. Force/moment magnitudes are cut reactions at the specified origin. The legacy impulse scalars integrate magnitudes and do not equal vector momentum change. Joint-coordinate speed norm and the ratio are coordinate-convention dependent. Analytic rates exclude discontinuous jumps and are not finite impact/shock measures. Negative generalized work is not automatically dissipation.</p></html>"));
    end InterfaceLoadMetrics;

    model KinematicSmoothnessMetrics
      "Acceleration and jerk exposure for a supplied point/COM acceleration signal"
      import SI = Modelica.Units.SI;
      input SI.Acceleration acceleration[3];
      output Real accelerationNorm(unit="m/s2");
      output Real jerk[3](each unit="m/s3");
      output Real jerkNorm(unit="m/s3");
      output Real jerkExposure(unit="m/s2",start=0,fixed=true);
    equation
      accelerationNorm=sqrt(sum(acceleration.^2));
      jerk=der(acceleration);
      jerkNorm=sqrt(sum(jerk.^2));
      der(jerkExposure)=jerkNorm;
    end KinematicSmoothnessMetrics;

    model Knee
      "1-DOF knee with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=1);
      parameter SI.Angle phi_start=0;
      parameter Boolean phi_fixed=false;
      parameter SI.AngularVelocity w_start=0;
      parameter Boolean w_fixed=false;
      parameter SI.RotationalSpringConstant kBase=0;
      parameter SI.RotationalDampingConstant cBase=0;
      parameter SI.Angle qNeutral=0;
      input Real stiffnessScale(min=0);
      input Real dampingScale(min=0);
      input Real stiffnessScaleRate(unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
      output SI.Angle q;
      output SI.AngularVelocity w;
      output Real limitUtilization;
      output SI.Force reactionForce[3]=frame_a.f;
      output SI.Torque reactionMoment[3]=frame_a.t;
      output SI.Torque generalizedTorque;
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.t);
      output SI.Power cutPowerIntoA=frame_a.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R,der(frame_a.r_0))
        +frame_a.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
      output SI.Power cutPowerIntoB=frame_b.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R,der(frame_b.r_0))
        +frame_b.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_b.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute rev(n={0,1,0},useAxisFlange=true,
        phi(start=phi_start,fixed=phi_fixed),w(start=w_start,fixed=w_fixed));
      VariableImpedance1D impedance(kBase=kBase,cBase=cBase,qNeutral=qNeutral);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=1,mobility=mobility);
    equation
      connect(frame_a,rev.frame_a); connect(rev.frame_b,frame_b);
      connect(rev.axis,impedance.flange_a); connect(rev.support,impedance.flange_b);
      impedance.stiffnessScale=stiffnessScale; impedance.dampingScale=dampingScale;
      impedance.stiffnessScaleRate=stiffnessScaleRate;
      q=rev.phi; w=rev.w; monitor.q={q}; limitUtilization=monitor.utilization[1];
      generalizedTorque=rev.tau; generalizedPower=generalizedTorque*w;
      stiffnessModulationPower=impedance.stiffnessModulationPowerToMechanical;
    end Knee;

    model AnkleComplex
      "2-DOF ankle with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=2);
      parameter SI.Angle q_start[2]={0,0};
      parameter Boolean q_fixed[2]=fill(false,2);
      parameter SI.AngularVelocity w_start[2]=fill(0,2);
      parameter Boolean w_fixed[2]=fill(false,2);
      parameter Boolean isLeft=true;
      parameter SI.RotationalSpringConstant kBase[2]={0,0};
      parameter SI.RotationalDampingConstant cBase[2]={0,0};
      parameter SI.Angle qNeutral[2]={0,0};
      input Real stiffnessScale[2];
      input Real dampingScale[2];
      input Real stiffnessScaleRate[2](each unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
      output SI.Angle q[2]; output SI.AngularVelocity w[2];
      output Real limitUtilization[2];
      output SI.Force reactionForce[3]=frame_a.f;
      output SI.Torque reactionMoment[3]=frame_a.t;
      output SI.Torque generalizedTorque[2];
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.t);
      output SI.Power cutPowerIntoA=frame_a.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R,der(frame_a.r_0))
        +frame_a.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
      output SI.Power cutPowerIntoB=frame_b.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R,der(frame_b.r_0))
        +frame_b.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_b.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute dorsiPlantar(n={0,-1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute inversionEversion(
        n=if isLeft then {-1,0,0} else {1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      VariableImpedance1D imp1(kBase=kBase[1],cBase=cBase[1],qNeutral=qNeutral[1]);
      VariableImpedance1D imp2(kBase=kBase[2],cBase=cBase[2],qNeutral=qNeutral[2]);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=2,mobility=mobility);
    equation
      connect(frame_a,dorsiPlantar.frame_a); connect(dorsiPlantar.frame_b,inversionEversion.frame_a);
      connect(inversionEversion.frame_b,frame_b);
      connect(dorsiPlantar.axis,imp1.flange_a); connect(dorsiPlantar.support,imp1.flange_b);
      connect(inversionEversion.axis,imp2.flange_a); connect(inversionEversion.support,imp2.flange_b);
      imp1.stiffnessScale=stiffnessScale[1]; imp1.dampingScale=dampingScale[1]; imp1.stiffnessScaleRate=stiffnessScaleRate[1];
      imp2.stiffnessScale=stiffnessScale[2]; imp2.dampingScale=dampingScale[2]; imp2.stiffnessScaleRate=stiffnessScaleRate[2];
      q={dorsiPlantar.phi,inversionEversion.phi}; w={dorsiPlantar.w,inversionEversion.w};
      monitor.q=q; limitUtilization=monitor.utilization;
      generalizedTorque={dorsiPlantar.tau,inversionEversion.tau};
      generalizedPower=sum(generalizedTorque.*w);
      stiffnessModulationPower=imp1.stiffnessModulationPowerToMechanical+imp2.stiffnessModulationPowerToMechanical;
    end AnkleComplex;

    model Hip
      "3-DOF hip with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3);
      parameter SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3);
      parameter Boolean isLeft=true;
      parameter SI.RotationalSpringConstant kBase[3]={0,0,0};
      parameter SI.RotationalDampingConstant cBase[3]={0,0,0};
      parameter SI.Angle qNeutral[3]={0,0,0};
      input Real stiffnessScale[3];
      input Real dampingScale[3];
      input Real stiffnessScaleRate[3](each unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
      output SI.Angle q[3]; output SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output SI.Force reactionForce[3]=frame_a.f;
      output SI.Torque reactionMoment[3]=frame_a.t;
      output SI.Torque generalizedTorque[3];
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.t);
      output SI.Power cutPowerIntoA=frame_a.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R,der(frame_a.r_0))
        +frame_a.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
      output SI.Power cutPowerIntoB=frame_b.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R,der(frame_b.r_0))
        +frame_b.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_b.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(n={0,-1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute addAbd(
        n=if isLeft then {-1,0,0} else {1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute intExt(
        n=if isLeft then {0,0,-1} else {0,0,1},useAxisFlange=true,
        phi(start=q_start[3],fixed=q_fixed[3]),w(start=w_start[3],fixed=w_fixed[3]));
      VariableImpedance1D imp[3](kBase=kBase,cBase=cBase,qNeutral=qNeutral);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3,mobility=mobility);
    equation
      connect(frame_a,flexExt.frame_a); connect(flexExt.frame_b,addAbd.frame_a);
      connect(addAbd.frame_b,intExt.frame_a); connect(intExt.frame_b,frame_b);
      connect(flexExt.axis,imp[1].flange_a); connect(flexExt.support,imp[1].flange_b);
      connect(addAbd.axis,imp[2].flange_a); connect(addAbd.support,imp[2].flange_b);
      connect(intExt.axis,imp[3].flange_a); connect(intExt.support,imp[3].flange_b);
      for i in 1:3 loop
        imp[i].stiffnessScale=stiffnessScale[i]; imp[i].dampingScale=dampingScale[i];
        imp[i].stiffnessScaleRate=stiffnessScaleRate[i];
      end for;
      q={flexExt.phi,addAbd.phi,intExt.phi}; w={flexExt.w,addAbd.w,intExt.w};
      monitor.q=q; limitUtilization=monitor.utilization;
      generalizedTorque={flexExt.tau,addAbd.tau,intExt.tau};
      generalizedPower=sum(generalizedTorque.*w);
      stiffnessModulationPower=sum(imp.stiffnessModulationPowerToMechanical);
    end Hip;

    model LumbarSpine3D
      "3-DOF lumbar joint with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3);
      parameter SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3);
      parameter SI.RotationalSpringConstant kBase[3]={0,0,0};
      parameter SI.RotationalDampingConstant cBase[3]={0,0,0};
      parameter SI.Angle qNeutral[3]={0,0,0};
      input Real stiffnessScale[3];
      input Real dampingScale[3];
      input Real stiffnessScaleRate[3](each unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvis;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_thorax;
      output SI.Angle q[3]; output SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output SI.Force reactionForce[3]=frame_pelvis.f;
      output SI.Torque reactionMoment[3]=frame_pelvis.t;
      output SI.Torque generalizedTorque[3];
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_pelvis.R,frame_pelvis.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_pelvis.R,frame_pelvis.t);
      output SI.Power cutPowerIntoA=frame_pelvis.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_pelvis.R,der(frame_pelvis.r_0))
        +frame_pelvis.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_pelvis.R);
      output SI.Power cutPowerIntoB=frame_thorax.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_thorax.R,der(frame_thorax.r_0))
        +frame_thorax.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_thorax.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(n={0,1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute lateralBend(n={-1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute axialRotation(n={0,0,1},useAxisFlange=true,
        phi(start=q_start[3],fixed=q_fixed[3]),w(start=w_start[3],fixed=w_fixed[3]));
      VariableImpedance1D imp[3](kBase=kBase,cBase=cBase,qNeutral=qNeutral);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3,mobility=mobility);
    equation
      connect(frame_pelvis,flexExt.frame_a); connect(flexExt.frame_b,lateralBend.frame_a);
      connect(lateralBend.frame_b,axialRotation.frame_a); connect(axialRotation.frame_b,frame_thorax);
      connect(flexExt.axis,imp[1].flange_a); connect(flexExt.support,imp[1].flange_b);
      connect(lateralBend.axis,imp[2].flange_a); connect(lateralBend.support,imp[2].flange_b);
      connect(axialRotation.axis,imp[3].flange_a); connect(axialRotation.support,imp[3].flange_b);
      for i in 1:3 loop
        imp[i].stiffnessScale=stiffnessScale[i]; imp[i].dampingScale=dampingScale[i];
        imp[i].stiffnessScaleRate=stiffnessScaleRate[i];
      end for;
      q={flexExt.phi,lateralBend.phi,axialRotation.phi}; w={flexExt.w,lateralBend.w,axialRotation.w};
      monitor.q=q; limitUtilization=monitor.utilization;
      generalizedTorque={flexExt.tau,lateralBend.tau,axialRotation.tau};
      generalizedPower=sum(generalizedTorque.*w);
      stiffnessModulationPower=sum(imp.stiffnessModulationPowerToMechanical);
    end LumbarSpine3D;

    model LowerBodyAxialAssembly
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
    protected
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
      LumbarSpine3D lumbar(mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,w_start=lumbarWStart,w_fixed=lumbarWFixed,kBase=lumbarK,cBase=lumbarC);
      ModelicaHumanBodyPArts.AxialBody.Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
      Hip leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=hipK,cBase=hipC,qNeutral=hipNeutral);
      Hip rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=hipK,cBase=hipC,qNeutral=hipNeutral);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation),rightThigh(props=thighProps,animation=animation);
      Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=kneeK,cBase=kneeC);
      Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=kneeK,cBase=kneeC);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation),rightShank(props=shankProps,animation=animation);
      AnkleComplex leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=ankleK,cBase=ankleC);
      AnkleComplex rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=ankleK,cBase=ankleC);
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
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
    end LowerBodyAxialAssembly;

    block QuinticYawMission
      "Analytic support-yaw mission profile with exact first and second derivatives available to Modelica"
      parameter Modelica.Units.SI.Angle amplitude=20*Modelica.Constants.pi/180;
      parameter Modelica.Units.SI.Time duration=0.25;
      output Modelica.Units.SI.Angle phi;
    protected
      Real u;
    equation
      u=min(1,max(0,time/duration));
      phi=amplitude*(10*u^3-15*u^4+6*u^5);
    end QuinticYawMission;

    model LiteratureRotationalTransmissionCase
      "Literature-informed rotational sensitivity case with transmission metrics; not a validated human prediction"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter Real lumbarKax(unit="N.m/rad")=19.480565
        "Watt 2022 ROM-quarter Q2 slope; constant sensitivity value, not population quartile";
      parameter Real lumbarCax(unit="N.m.s/rad")=0.8 "Explicit damping assumption";
      parameter Real hipKax(unit="N.m/rad")=4 "S50-R1 sensitivity parameter; not a human constant";
      parameter Real hipCax(unit="N.m.s/rad")=4 "S50-R1 sensitivity parameter; not a human constant";
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.224,hipCenterDistance=0.20,geometrySourceId="MIXED_PUBLIC_LITERATURE_NOMINAL_MALE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=10.65,length=0.224,rCM={-0.075264,0.000672,-0.033376},I_CM={{0.09426364,0.00133594,-0.00534374},{0.00133594,0.08549990,0.00048094},{-0.00534374,0.00048094,0.10345488}},R_principal=identity(3),segmentFrameId="DUMAS2007_MALE_PELVIS_CONVERTED_X_ANT_Y_LEFT_Z_SUP");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=24.975,length=0.485,rCM={0.00227498,0.00125910,0.28193904},I_CM={{0.545069637,-0.000030015,-0.019639192},{-0.000030015,0.420862030,-0.002521310},{-0.019639192,-0.002521310,0.299943509}},R_principal=identity(3),segmentFrameId="DUMAS2015_MALE_ABDOMEN_PLUS_THORAX_COMPOSITE_AT_LJC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SENSITIVITY_GATE_NOT_CLINICAL_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-1},qMax={2.8},sourceId="SENSITIVITY_GATE_NOT_CLINICAL_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SENSITIVITY_GATE_NOT_CLINICAL_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-1,-1,-24*Modelica.Constants.pi/180},qMax={1,1,24*Modelica.Constants.pi/180},sourceId="ASSUMED_PLUS_MINUS_24_DEG_NOT_SHIN_TOTAL_RANGE");
      Modelica.Mechanics.MultiBody.Parts.Fixed ground(animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute standingYaw(n={0,0,1},useAxisFlange=true,phi(start=0,fixed=true),w(start=0,fixed=true));
      Modelica.Mechanics.Rotational.Sources.Torque torqueSource(useSupport=true);
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.224,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,hipK={0,0,hipKax},hipC={0,0,hipCax},lumbarK={0,0,lumbarKax},lumbarC={0,0,lumbarCax},fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      InterfaceLoadMetrics hipMetrics(n=3,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      InterfaceLoadMetrics kneeMetrics(n=1,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      InterfaceLoadMetrics ankleMetrics(n=2,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      InterfaceLoadMetrics lumbarMetrics(n=3,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      output SI.Torque appliedGroundTorque;
      output SI.Angle standingFootYaw=standingYaw.phi,standingHipAxial=body.leftQ[3],freeHipAxial=body.rightQ[3],pelvisYawProxy=standingFootYaw+standingHipAxial,lumbarAxial=body.lumbarQ[3],thoraxYawProxy=pelvisYawProxy+lumbarAxial;
      output Real lumbarUtilization=abs(lumbarAxial)/(24*Modelica.Constants.pi/180);
      output Real hipForceBW=hipMetrics.forcePerDeclaredBW,kneeForceBW=kneeMetrics.forcePerDeclaredBW,
        ankleForceBW=ankleMetrics.forcePerDeclaredBW,lumbarForceBW=lumbarMetrics.forcePerDeclaredBW;
      output SI.Torque hipMoment=hipMetrics.momentNorm,kneeMoment=kneeMetrics.momentNorm,
        ankleMoment=ankleMetrics.momentNorm,lumbarMoment=lumbarMetrics.momentNorm;
      output Real hipForceRate=hipMetrics.forceLoadingRate,kneeForceRate=kneeMetrics.forceLoadingRate,
        ankleForceRate=ankleMetrics.forceLoadingRate,lumbarForceRate=lumbarMetrics.forceLoadingRate;
      output Real hipMomentRate=hipMetrics.momentLoadingRate,kneeMomentRate=kneeMetrics.momentLoadingRate,
        ankleMomentRate=ankleMetrics.momentLoadingRate,lumbarMomentRate=lumbarMetrics.momentLoadingRate;
      output Real hipForceImpulse=hipMetrics.forceImpulse,kneeForceImpulse=kneeMetrics.forceImpulse,
        ankleForceImpulse=ankleMetrics.forceImpulse,lumbarForceImpulse=lumbarMetrics.forceImpulse;
      output Real hipMomentImpulse=hipMetrics.momentImpulse,kneeMomentImpulse=kneeMetrics.momentImpulse,
        ankleMomentImpulse=ankleMetrics.momentImpulse,lumbarMomentImpulse=lumbarMetrics.momentImpulse;
      output SI.Power hipPower=hipMetrics.generalizedPower,kneePower=kneeMetrics.generalizedPower,
        anklePower=ankleMetrics.generalizedPower,lumbarPower=lumbarMetrics.generalizedPower;
      output SI.Energy hipPositiveWork=hipMetrics.positiveWork,kneePositiveWork=kneeMetrics.positiveWork,
        anklePositiveWork=ankleMetrics.positiveWork,lumbarPositiveWork=lumbarMetrics.positiveWork;
      output SI.Energy hipNegativeWork=hipMetrics.negativeWork,kneeNegativeWork=kneeMetrics.negativeWork,
        ankleNegativeWork=ankleMetrics.negativeWork,lumbarNegativeWork=lumbarMetrics.negativeWork;
      output Real hipHighLoadLowMotion=hipMetrics.highLoadLowMotionRatio,
        kneeHighLoadLowMotion=kneeMetrics.highLoadLowMotionRatio,
        ankleHighLoadLowMotion=ankleMetrics.highLoadLowMotionRatio,
        lumbarHighLoadLowMotion=lumbarMetrics.highLoadLowMotionRatio;
    equation
      connect(ground.frame_b,standingYaw.frame_a); connect(standingYaw.frame_b,body.leftPlantarFrames[1]); connect(torqueSource.flange,standingYaw.axis); connect(torqueSource.support,standingYaw.support);
      appliedGroundTorque=if time<0.05 then 0 else if time<0.25 then 5 else 0; torqueSource.tau=appliedGroundTorque;
      hipMetrics.force=body.leftHipReactionForce; hipMetrics.moment=body.leftHipReactionMoment; hipMetrics.generalizedTorque=body.leftHipTorque; hipMetrics.generalizedSpeed=body.leftW[1:3];
      kneeMetrics.force=body.leftKneeReactionForce; kneeMetrics.moment=body.leftKneeReactionMoment; kneeMetrics.generalizedTorque={body.leftKneeTorque}; kneeMetrics.generalizedSpeed={body.leftW[4]};
      ankleMetrics.force=body.leftAnkleReactionForce; ankleMetrics.moment=body.leftAnkleReactionMoment; ankleMetrics.generalizedTorque=body.leftAnkleTorque; ankleMetrics.generalizedSpeed=body.leftW[5:6];
      lumbarMetrics.force=body.lumbosacralForce; lumbarMetrics.moment=body.lumbosacralMoment; lumbarMetrics.generalizedTorque=body.lumbarTorque; lumbarMetrics.generalizedSpeed=body.lumbarW;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.0005),Documentation(info="<html><p>Pelvis/thorax mass properties are literature-informed project inputs. Watt et al. 2022 motivates range-quarter slope sensitivity; lumbar damping and hip impedance remain explicit sensitivity assumptions. Shin 2013 reports a 23.9 degree summed left-to-right excursion, not a plus/minus 24 degree bound. The retained plus/minus 24 degree gate is an explicit unvalidated numerical assumption. Watt quartiles refer to quarters of motion range, not four population quartiles. This is not human validation of Lynkorr.</p></html>"));
    end LiteratureRotationalTransmissionCase;

    model LoadMetricsAnalyticTest
      "Analytic verification of wrench magnitude, loading rates, impulses and work"
      InterfaceLoadMetrics m(n=1,declaredBodyMass=1,representedMass=1,g=10);
      output Integer checksPassed(start=0,fixed=true);
    equation
      m.force={3*time,4*time,0}; m.moment={0,0,2*time}; m.generalizedTorque={2*time}; m.generalizedSpeed={1};
    algorithm
      when time>=0.999 then
        assert(abs(m.forceNorm-5*time)<1e-7,"Force norm mismatch");
        assert(abs(m.forceLoadingRate-5)<1e-6,"Force loading-rate mismatch");
        assert(abs(m.momentLoadingRate-2)<1e-6,"Moment loading-rate mismatch");
        assert(abs(m.forceImpulse-2.5)<0.01,"Force impulse mismatch");
        assert(abs(m.momentImpulse-1)<0.01,"Moment impulse mismatch");
        assert(abs(m.positiveWork-1)<0.01,"Positive work mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-9,Interval=0.001));
    end LoadMetricsAnalyticTest;

    model KinematicSmoothnessAnalyticTest
      "Analytic verification of acceleration-to-jerk diagnostics"
      KinematicSmoothnessMetrics m;
      output Integer checksPassed(start=0,fixed=true);
    equation
      m.acceleration={time^2,0,0};
    algorithm
      when time>=0.999 then
        assert(abs(m.jerk[1]-2*time)<1e-6,"Jerk mismatch");
        assert(abs(m.jerkExposure-1)<0.01,"Jerk exposure mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-9,Interval=0.001));
    end KinematicSmoothnessAnalyticTest;

    model VariableImpedanceEnergyBalanceTest
      "Verification that time-varying stiffness accounts explicitly for modulation energy"
      Modelica.Mechanics.Rotational.Components.Fixed fixed;
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J=0.2,phi(start=0.2,fixed=true),w(start=0,fixed=true));
      VariableImpedance1D imp(kBase=20,cBase=0.5,qNeutral=0);
      SmoothImpedanceSchedule schedule(initialScale=1,preparationScale=1.1,releaseScale=0.5,preparationEnd=0.1,releaseEnd=0.6);
      output Modelica.Units.SI.Energy dissipatedEnergy(start=0,fixed=true);
      output Modelica.Units.SI.Energy modulationEnergy(start=0,fixed=true);
      output Modelica.Units.SI.Energy mechanicalEnergy=0.5*inertia.J*inertia.w^2+imp.elasticEnergy;
      output Modelica.Units.SI.Energy integratedEnergyResidual=mechanicalEnergy+dissipatedEnergy-modulationEnergy-0.4;
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(inertia.flange_a,imp.flange_a); connect(fixed.flange,imp.flange_b);
      imp.stiffnessScale=schedule.scale; imp.dampingScale=schedule.scale; imp.stiffnessScaleRate=schedule.scaleRate;
      der(dissipatedEnergy)=imp.dampingDissipationPower;
      der(modulationEnergy)=imp.modulationPowerIntoStorage;
    algorithm
      when time>=0.9 then
        assert(abs(integratedEnergyResidual)<1e-6,"Integrated inertial/elastic/modulation energy failed");
        assert(abs(imp.energyBalanceResidual)<1e-8,"Variable-impedance energy balance failed");
        assert(imp.dampingDissipationPower>=-1e-10,"Damping dissipation became negative");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-9,Interval=0.001));
    end VariableImpedanceEnergyBalanceTest;

    model ImpedanceScheduleNoPropulsionTest
      "Changing impedance at zero displacement/velocity must not create motion or power"
      Modelica.Mechanics.Rotational.Components.Fixed fixed;
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J=0.2,phi(start=0,fixed=true),w(start=0,fixed=true));
      VariableImpedance1D imp(kBase=20,cBase=1,qNeutral=0);
      SmoothImpedanceSchedule schedule;
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(inertia.flange_a,imp.flange_a); connect(fixed.flange,imp.flange_b);
      imp.stiffnessScale=schedule.scale; imp.dampingScale=schedule.scale; imp.stiffnessScaleRate=schedule.scaleRate;
    algorithm
      when time>=0.49 then
        assert(abs(inertia.phi)<1e-12 and abs(inertia.w)<1e-12,"Impedance schedule generated motion from the zero state");
        assert(abs(imp.mechanicalPowerIntoElement)<1e-12 and abs(imp.stiffnessModulationPowerToMechanical)<1e-12,"Impedance schedule generated power from zero deformation");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-9,Interval=0.001));
    end ImpedanceScheduleNoPropulsionTest;

    model MatchedImpedanceTaskTest
      "Two identical bodies follow the same support-yaw mission; only internal impedance schedule differs"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.224,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_MATCHED_IMPEDANCE_TASK");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=10.65,length=0.224,rCM={-0.075264,0.000672,-0.033376},I_CM={{0.09426364,0.00133594,-0.00534374},{0.00133594,0.08549990,0.00048094},{-0.00534374,0.00048094,0.10345488}},R_principal=identity(3),segmentFrameId="LITERATURE_INFORMED_PROJECT_INPUT");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=24.975,length=0.485,rCM={0.00227498,0.00125910,0.28193904},I_CM={{0.545069637,-0.000030015,-0.019639192},{-0.000030015,0.420862030,-0.002521310},{-0.019639192,-0.002521310,0.299943509}},R_principal=identity(3),segmentFrameId="LITERATURE_INFORMED_PROJECT_INPUT");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SENSITIVITY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-1},qMax={2.8},sourceId="SENSITIVITY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SENSITIVITY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-1,-1,-24*Modelica.Constants.pi/180},qMax={1,1,24*Modelica.Constants.pi/180},sourceId="ASSUMED_PLUS_MINUS_24_DEG_NOT_MEASURED");
      Modelica.Mechanics.MultiBody.Parts.Fixed groundHold(animation=false),groundRelease(animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute yawHold(n={0,0,1},useAxisFlange=true),yawRelease(n={0,0,1},useAxisFlange=true);
      Modelica.Mechanics.Rotational.Sources.Position posHold(exact=true,useSupport=true),posRelease(exact=true,useSupport=true);
      QuinticYawMission mission;
      SmoothImpedanceSchedule releaseSchedule(initialScale=1,preparationScale=1.2,releaseScale=0.45,preparationEnd=0.05,releaseEnd=0.25);
      LowerBodyAxialAssembly hold(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.224,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,hipK={0,0,4},hipC={0,0,4},lumbarK={0,0,19.480565},lumbarC={0,0,0.8},fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      LowerBodyAxialAssembly release(useVariableImpedance=true,profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.224,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,hipK={0,0,4},hipC={0,0,4},lumbarK={0,0,19.480565},lumbarC={0,0,0.8},fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      InterfaceLoadMetrics holdHip(n=3,declaredBodyMass=75,representedMass=hold.representedMass),releaseHip(n=3,declaredBodyMass=75,representedMass=release.representedMass);
      InterfaceLoadMetrics holdLumbar(n=3,declaredBodyMass=75,representedMass=hold.representedMass),releaseLumbar(n=3,declaredBodyMass=75,representedMass=release.representedMass);
      output SI.Angle supportYawHold=yawHold.phi,supportYawRelease=yawRelease.phi;
      output SI.Angle pelvisYawHold=supportYawHold+hold.leftQ[3],pelvisYawRelease=supportYawRelease+release.leftQ[3];
      output SI.Angle lumbarYawHold=hold.lumbarQ[3],lumbarYawRelease=release.lumbarQ[3];
      output SI.Angle thoraxYawHold=pelvisYawHold+lumbarYawHold,thoraxYawRelease=pelvisYawRelease+lumbarYawRelease;
      output Real hipMomentImpulseHold=holdHip.momentImpulse,hipMomentImpulseRelease=releaseHip.momentImpulse;
      output Real lumbarMomentImpulseHold=holdLumbar.momentImpulse,lumbarMomentImpulseRelease=releaseLumbar.momentImpulse;
      output SI.Energy hipNegativeWorkHold=holdHip.negativeWork,hipNegativeWorkRelease=releaseHip.negativeWork;
      output SI.Energy lumbarNegativeWorkHold=holdLumbar.negativeWork,lumbarNegativeWorkRelease=releaseLumbar.negativeWork;
      output SI.Power releaseModulationPower=release.totalStiffnessModulationPower;
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(groundHold.frame_b,yawHold.frame_a); connect(yawHold.frame_b,hold.leftPlantarFrames[1]); connect(posHold.flange,yawHold.axis); connect(posHold.support,yawHold.support); posHold.phi_ref=mission.phi;
      connect(groundRelease.frame_b,yawRelease.frame_a); connect(yawRelease.frame_b,release.leftPlantarFrames[1]); connect(posRelease.flange,yawRelease.axis); connect(posRelease.support,yawRelease.support); posRelease.phi_ref=mission.phi;
      release.leftHipControl={1,1,releaseSchedule.scale,1,1,releaseSchedule.scale,0,0,releaseSchedule.scaleRate};
      release.rightHipControl={1,1,releaseSchedule.scale,1,1,releaseSchedule.scale,0,0,releaseSchedule.scaleRate};
      release.lumbarControl={1,1,releaseSchedule.scale,1,1,releaseSchedule.scale,0,0,releaseSchedule.scaleRate};
      holdHip.force=hold.leftHipReactionForce; holdHip.moment=hold.leftHipReactionMoment; holdHip.generalizedTorque=hold.leftHipTorque; holdHip.generalizedSpeed=hold.leftW[1:3];
      releaseHip.force=release.leftHipReactionForce; releaseHip.moment=release.leftHipReactionMoment; releaseHip.generalizedTorque=release.leftHipTorque; releaseHip.generalizedSpeed=release.leftW[1:3];
      holdLumbar.force=hold.lumbosacralForce; holdLumbar.moment=hold.lumbosacralMoment; holdLumbar.generalizedTorque=hold.lumbarTorque; holdLumbar.generalizedSpeed=hold.lumbarW;
      releaseLumbar.force=release.lumbosacralForce; releaseLumbar.moment=release.lumbosacralMoment; releaseLumbar.generalizedTorque=release.lumbarTorque; releaseLumbar.generalizedSpeed=release.lumbarW;
    algorithm
      when time>=0.49 then
        assert(abs(supportYawHold-supportYawRelease)<1e-10,"Matched task support trajectories diverged");
        assert(abs(supportYawHold-mission.amplitude)<1e-8,"Matched task did not reach prescribed support yaw");
        assert(abs(lumbarYawHold-lumbarYawRelease)>1e-6 or abs(pelvisYawHold-pelvisYawRelease)>1e-6,"Impedance schedule produced no detectable internal mechanical difference");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.0005),Documentation(info="<html><p>This is a matched external kinematic mission, not a matched whole-body endpoint. Both bodies receive the same standing-support yaw trajectory and duration; only the hip/lumbar impedance schedule differs. No conclusion that one strategy is biologically superior is encoded in the assertions.</p></html>"));
    end MatchedImpedanceTaskTest;

    model TransmissionAssemblyBuild
      "Build-only fixture for the v0.9.1 transmission architecture"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_V091_BUILD");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_V091_BUILD");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.50,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),segmentFrameId="SYNTHETIC_V091_BUILD");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-0.5,-0.5,-0.5},qMax={0.5,0.5,0.5},sourceId="SYNTHETIC");
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,1.1},animation=false);
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.10,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},animation=false);
    equation
      connect(anchor.frame_b,body.frame_pelvisReference);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end TransmissionAssemblyBuild;


    block SpatialWrenchPower
      "Full cut power from a wrench and twist at one common origin and reporting frame"
      input Modelica.Units.SI.Force force[3];
      input Modelica.Units.SI.Torque moment[3];
      input Modelica.Units.SI.Velocity velocity[3];
      input Modelica.Units.SI.AngularVelocity angularVelocity[3];
      output Modelica.Units.SI.Power power=force*velocity+moment*angularVelocity;
    end SpatialWrenchPower;

    model SpatialWrenchPowerAnalyticTest
      "Power is invariant under a consistent common-origin shift; Q*qdot is a different quantity"
      SpatialWrenchPower a,b;
      output Integer checksPassed(start=0,fixed=true);
    equation
      a.force={3,4,0}; a.moment={0,0,2};
      a.velocity={1,0,0}; a.angularVelocity={0,0,7};
      b.force=a.force; b.angularVelocity=a.angularVelocity;
      b.moment=a.moment-cross({1,0,0},a.force);
      b.velocity=a.velocity+cross(a.angularVelocity,{1,0,0});
    algorithm
      when time>=0.009 then
        assert(abs(a.power-17)<1e-12 and abs(b.power-a.power)<1e-12,
          "Spatial power origin-shift identity failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-9));
    end SpatialWrenchPowerAnalyticTest;

    model ImpedanceNonzeroNeutralTest
      "A nonzero declared neutral posture remains at rest without external drive"
      Modelica.Mechanics.Rotational.Components.Fixed base;
      Modelica.Mechanics.Rotational.Components.Inertia body(J=0.2,phi(start=0.15,fixed=true),w(start=0,fixed=true));
      VariableImpedance1D imp(kBase=20,cBase=0.5,qNeutral=0.15);
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(body.flange_a,imp.flange_a);connect(base.flange,imp.flange_b);
      imp.stiffnessScale=1;imp.dampingScale=1;imp.stiffnessScaleRate=0;
    algorithm
      when time>=0.49 then
        assert(abs(body.phi-0.15)<1e-10 and abs(body.w)<1e-10 and abs(imp.restoringTorque)<1e-10,
          "Nonzero neutral angle sign or equilibrium failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.5,Tolerance=1e-9));
    end ImpedanceNonzeroNeutralTest;


    model LegacyNeutralEquilibriumTest
      "Legacy hip and lumbar joints hold a nonzero declared neutral posture"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(
        n=3,qMin=fill(-1,3),qMax=fill(1,3),sourceId="SYNTHETIC_NEUTRAL_SIGN_TEST");
      parameter Modelica.Units.SI.Angle neutral[3]={0.1,0.08,-0.12};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchors[2](each animation=false);
      ModelicaHumanBodyPArts.Joints.Hip hip(mobility=rom,qNeutral=neutral,
        q_start=neutral,q_fixed=fill(true,3),w_fixed=fill(true,3),
        kPassive=fill(20,3),cPassive=fill(1,3));
      ModelicaHumanBodyPArts.AxialBody.LumbarSpine3D lumbar(mobility=rom,qNeutral=neutral,
        q_start=neutral,q_fixed=fill(true,3),w_fixed=fill(true,3),
        kPassive=fill(20,3),cPassive=fill(1,3));
      Modelica.Mechanics.MultiBody.Parts.Body masses[2](each animation=false,
        each m=1,each r_CM={0,0,0},each I_11=0.1,each I_22=0.1,each I_33=0.1);
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(anchors[1].frame_b,hip.frame_a);connect(hip.frame_b,masses[1].frame_a);
      connect(anchors[2].frame_b,lumbar.frame_pelvis);connect(lumbar.frame_thorax,masses[2].frame_a);
    algorithm
      when time>=0.49 then
        assert(max(abs(hip.q-neutral))<1e-9 and max(abs(lumbar.q-neutral))<1e-9,
          "Legacy nonzero neutral-angle convention failed");
        assert(max(abs(hip.w))<1e-9 and max(abs(lumbar.w))<1e-9,
          "Legacy neutral posture generated motion");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.5,Tolerance=1e-9));
    end LegacyNeutralEquilibriumTest;

  end Transmission;

