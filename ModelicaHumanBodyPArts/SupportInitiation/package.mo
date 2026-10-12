within ModelicaHumanBodyPArts;
  package SupportInitiation
    "M2b: gravity-loaded support-side actuation, passive free leg, checked rigid contact"
    extends Modelica.Icons.Package;
    function unitStep5
      input Real u;
      output Real y;
    algorithm
      y:=if u<=0 then 0 else if u>=1 then 1 else 10*u^3-15*u^4+6*u^5;
    end unitStep5;
    block SmoothSupportPulse
      parameter Modelica.Units.SI.Time onset=0.10,rise=0.10,hold=0.15,fall=0.10;
      output Real y;
    equation
      assert(rise>0 and fall>0 and hold>=0,"Invalid pulse times");
      y=unitStep5((time-onset)/rise)-unitStep5((time-onset-rise-hold)/fall);
    end SmoothSupportPulse;
    model HipDrive
      "Standing hip only: explicit internal drive, no free-leg active source"
      extends ModelicaHumanBodyPArts.Transmission.Hip;
      input Modelica.Units.SI.Torque drive[3];
    protected
      Modelica.Mechanics.Rotational.Sources.Torque motor[3](each useSupport=true);
    equation
      connect(motor[1].flange,flexExt.axis);connect(motor[1].support,flexExt.support);
      connect(motor[2].flange,addAbd.axis);connect(motor[2].support,addAbd.support);
      connect(motor[3].flange,intExt.axis);connect(motor[3].support,intExt.support);
      for j in 1:3 loop motor[j].tau=drive[j];end for;
    end HipDrive;
    model AnkleDrive
      "Standing ankle only: shear-inducing internal pitch effort"
      extends ModelicaHumanBodyPArts.Transmission.AnkleComplex;
      input Modelica.Units.SI.Torque drive[2];
    protected
      Modelica.Mechanics.Rotational.Sources.Torque motor[2](each useSupport=true);
    equation
      connect(motor[1].flange,dorsiPlantar.axis);connect(motor[1].support,dorsiPlantar.support);
      connect(motor[2].flange,inversionEversion.axis);connect(motor[2].support,inversionEversion.support);
      for j in 1:2 loop motor[j].tau=drive[j];end for;
    end AnkleDrive;

    model LoadedSupportBody
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
      parameter SI.Angle restAngles[15]={-0.007051898347754103,-0.05616621149897582,-0.0408266154749981,0.005876581951724801,-0.003525949171034881,-0.115275665089173,0.5320759336827905,-0.2669810911015702,0.1301746337389886,0.6048192081043453,0.294847674871562,0.115275665089173,0,-0.007052196139056831,0};
      parameter SI.RotationalSpringConstant stiffness[15]={1000,1000,20,1200,2000,2000,25,20,4,20,10,10,1000,1000,20};
      parameter SI.RotationalDampingConstant damping[15]={60,60,2,60,100,100,1.5,2,1.5,1,1,1,50,50,1};
      input SI.Torque ankleActuation;
      input SI.Torque hipYawActuation;
      output SI.Position freeHipWorld[3]=rightHip.frame_a.r_0;
      output SI.Position freeFootWorld[3]=rightFoot.frame_ankle.r_0;
      output SI.Position freeFootRelativePelvis[3]=Modelica.Mechanics.MultiBody.Frames.resolve2(
        pelvis.frame_lumbosacral.R,freeFootWorld-freeHipWorld);
      output SI.Length freeHipToFoot=sqrt(sum((freeFootWorld-freeHipWorld).^2));
      output SI.Length freeSoleHeight[6]={rightPlantarFrames[i].r_0[3] for i in 1:6};
      output SI.Angle allQ[15]=cat(1,leftQ,rightQ,lumbarQ);
      output SI.AngularVelocity allW[15]=cat(1,leftW,rightW,lumbarW);
      output SI.Energy kineticEnergy,potentialEnergy,elasticEnergy,mechanicalEnergy;
      output SI.RotationalSpringConstant actualStiffness[15];
      output SI.RotationalDampingConstant actualDamping[15];
      output SI.Power actuatorPower=ankleActuation*leftW[5]+hipYawActuation*leftW[3];
      output SI.Power dissipationPower;
      output SI.Power modulationPowerIntoStorage=-totalStiffnessModulationPower;
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
      ModelicaHumanBodyPArts.Transmission.LumbarSpine3D lumbar(mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,w_start=lumbarWStart,w_fixed=lumbarWFixed,kBase=stiffness[13:15],cBase=damping[13:15],qNeutral=restAngles[13:15]);
      ModelicaHumanBodyPArts.AxialBody.Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
      HipDrive leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=stiffness[1:3],cBase=damping[1:3],qNeutral=restAngles[1:3]);
      ModelicaHumanBodyPArts.Transmission.Hip rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=stiffness[7:9],cBase=damping[7:9],qNeutral=restAngles[7:9]);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation),rightThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Transmission.Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=stiffness[4],cBase=damping[4],qNeutral=restAngles[4]);
      ModelicaHumanBodyPArts.Transmission.Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=stiffness[10],cBase=damping[10],qNeutral=restAngles[10]);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation),rightShank(props=shankProps,animation=animation);
      AnkleDrive leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=stiffness[5:6],cBase=damping[5:6],qNeutral=restAngles[5:6]);
      ModelicaHumanBodyPArts.Transmission.AnkleComplex rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=stiffness[11:12],cBase=damping[11:12],qNeutral=restAngles[11:12]);
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
      leftAnkle.drive={ankleActuation,0};
      leftHip.drive={0,0,hipYawActuation};
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
      potentialEnergy=9.81*sum({segmentMasses[i]*segmentCOMWorld[i,3] for i in 1:8});
      actualStiffness=cat(1,stiffness[1:3].*leftHipKScale,{stiffness[4]},stiffness[5:6],stiffness[7:9].*rightHipKScale,{stiffness[10]},stiffness[11:12],stiffness[13:15].*lumbarKScale);
      actualDamping=cat(1,damping[1:3].*leftHipCScale,{damping[4]},damping[5:6],damping[7:9].*rightHipCScale,{damping[10]},damping[11:12],damping[13:15].*lumbarCScale);
      elasticEnergy=0.5*sum(actualStiffness.*(allQ-restAngles).^2);
      dissipationPower=sum(actualDamping.*allW.^2);
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
    end LoadedSupportBody;

    model M2bLoadedSupport
      "Loaded single support: ankle pitch + stance hip yaw; external reactions solved, not imposed"
      import SI=Modelica.Units.SI;
      parameter Boolean shearEnabled=true,yawEnabled=true;
      parameter SI.Torque anklePulse=15,hipYawPulse=4;
      parameter Real mu(min=0)=0.6;
      parameter Boolean enforceNecessaryContactGate=true;
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1},g=9.81,
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,enableAnimation=false);
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
      parameter SI.Angle initialQ[15]={0,0,0,0,0,-0.115275665089173,0.25,0,0,0.5,0.25,0.115275665089173,0,0,0};
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,0.08},animation=false);
      SmoothSupportPulse pulse;
      LoadedSupportBody body(profile=profile,pelvicProps=pp,thoraxProps=tp,
        lumbosacralToHipVertical=0.1,shoulderWidth=0.4,footCOMAboveSole=0.035,
        footCOMOffsetSourceId="SYNTHETIC_M2B_OFFSET",hipMobility=hipROM,kneeMobility=kneeROM,
        ankleMobility=ankleROM,lumbarMobility=lumbarROM,leftHipStart=initialQ[1:3],
        leftKneeStart=initialQ[4],leftAnkleStart=initialQ[5:6],rightHipStart=initialQ[7:9],
        rightKneeStart=initialQ[10],rightAnkleStart=initialQ[11:12],lumbarStart=initialQ[13:15],
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        lumbarFixed=fill(true,3),lumbarWFixed=fill(true,3),animation=false);
      output SI.Force groundForce[3]=-support.frame_b.f;
      output SI.Torque groundMoment[3]=-support.frame_b.t+cross({0,0,0.08},groundForce);
      output SI.Force footOnGroundForce[3]=-groundForce;
      output SI.Position cop[2];
      output Real frictionUtilization;
      output Boolean necessaryContactGate;
      output SI.Force forceBalanceResidual[3];
      output SI.Length freeFootWorldDelta[3]=body.freeFootWorld-freeWorld0;
      output SI.Length freeFootRelativeDelta[3]=body.freeFootRelativePelvis-freeRelative0;
      output SI.Length freeHipFootChange=body.freeHipToFoot-freeDistance0;
      output SI.Velocity freeFootWorldVelocity[3]=der(body.freeFootWorld);
      output SI.Length minFreeSoleClearance=min(body.freeSoleHeight);
      output SI.Angle pelvisYaw=body.pelvisYawWorld,thoraxYaw=body.thoraxYawWorld;
      output SI.Angle lumbarAxial=body.lumbarQ[3],freeHipFlexion=body.rightQ[1],freeKnee=body.rightQ[4];
      output SI.Energy actuatorWork(start=0,fixed=true),dampingLoss(start=0,fixed=true);
      output SI.Energy energyBalanceResidual=body.mechanicalEnergy-energy0+dampingLoss-actuatorWork;
      output Integer checksPassed(start=0,fixed=true);
    protected
      parameter SI.Position freeWorld0[3](each fixed=false),freeRelative0[3](each fixed=false);
      parameter SI.Length freeDistance0(fixed=false);
      parameter SI.Energy energy0(fixed=false);
    initial equation
      freeWorld0=body.freeFootWorld;freeRelative0=body.freeFootRelativePelvis;
      freeDistance0=body.freeHipToFoot;energy0=body.mechanicalEnergy;
    equation
      connect(support.frame_b,body.leftFootReference);
      body.ankleActuation=if shearEnabled then anklePulse*pulse.y else 0;
      body.hipYawActuation=if yawEnabled then hipYawPulse*pulse.y else 0;
      cop=if groundForce[3]>1e-6 then {-groundMoment[2],groundMoment[1]}/groundForce[3] else {0,0};
      frictionUtilization=sqrt(groundForce[1]^2+groundForce[2]^2)/max(mu*groundForce[3],1e-6);
      necessaryContactGate=groundForce[3]>0 and cop[1]>=-0.07 and cop[1]<=0.19
        and abs(cop[2])<=0.0475 and frictionUtilization<=1;
      forceBalanceResidual=groundForce+{0,0,-9.81*body.representedMass}
        -body.representedMass*body.representedCOMAcceleration;
      der(actuatorWork)=body.actuatorPower;der(dampingLoss)=body.dissipationPower;
      assert(not enforceNecessaryContactGate or necessaryContactGate,
        "Required rigid-contact force/COP/friction gate failed; this is not a valid stance sample");
      assert(minFreeSoleClearance>=-1e-6,"Free-foot clearance violated; no impact model is present");
    algorithm
      when time>=0.74 then
        assert(max(abs(forceBalanceResidual))<1e-4,"Whole represented-body force balance failed");
        assert(abs(energyBalanceResidual)<1e-3,"Energy balance with explicit actuator work failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.75,Interval=0.0025,Tolerance=1e-8),
        Documentation(info="<html><p>New gravity-loaded functional fixture, not a complete dance or a human validation. Stationary rigid foot constraint is admissible only when the returned contact wrench is feasible. A separate corner-force friction-cone test is required in addition to the necessary in-model gates. External Fx, Mz and Fz are measured reactions; only ankle-pitch and stance-hip-yaw torque pulses are commanded. Free-leg joints have fixed passive preloads derived from initial gravity equilibrium; no free target, controller or active source. Initial posture/preloads are synthetic and not physiological measurements. Free-leg forward response is not an assertion: zero, backward or inferior outcomes must remain reported.</p></html>"));
    end M2bLoadedSupport;
    model M2bBaseline
      extends M2bLoadedSupport(shearEnabled=false,yawEnabled=false);
    end M2bBaseline;
    model M2bShearOnly
      extends M2bLoadedSupport(shearEnabled=true,yawEnabled=false);
    end M2bShearOnly;
    model M2bYawOnly
      extends M2bLoadedSupport(shearEnabled=false,yawEnabled=true);
    end M2bYawOnly;
    model M2bCombined
      extends M2bLoadedSupport(shearEnabled=true,yawEnabled=true);
    end M2bCombined;
  end SupportInitiation;

