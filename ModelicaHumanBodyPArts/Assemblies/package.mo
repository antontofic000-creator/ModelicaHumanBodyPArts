within ModelicaHumanBodyPArts;
  package Assemblies
    extends Modelica.Icons.Package;
  
    model LowerBodyAssembly
      "First bilateral lower-body assembly; no ground contact yet"
      import SI = Modelica.Units.SI;
    
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter Modelica.Units.SI.Angle leftHipStart[3]=zeros(3), rightHipStart[3]=zeros(3);
      parameter Modelica.Units.SI.Angle leftKneeStart=0, rightKneeStart=0;
      parameter Modelica.Units.SI.Angle leftAnkleStart[2]=zeros(2), rightAnkleStart[2]=zeros(2);
      parameter Modelica.Units.SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
    
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftAnkleMobility(n=2)=ankleMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightAnkleMobility(n=2)=ankleMobility;
    
    
      parameter Boolean animation=true;
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisProximal;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference
        "Rigid reference frame on left foot for pure contact moments";
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightFootReference
        "Rigid reference frame on right foot for pure contact moments";
    
      output SI.Mass representedMass
        "Mass of explicit lower-body segments; NOT profile.mass or a complete human";
      output Real leftAnkleLimitUtilization[2];
      output Real rightAnkleLimitUtilization[2];
      output Real leftKneeLimitUtilization;
      output Real rightKneeLimitUtilization;
      output Real leftHipLimitUtilization[3];
      output Real rightHipLimitUtilization[3];
    
      output SI.Angle leftQ[6] "Hip 1:3, knee 4, ankle 5:6; diagnostic only";
      output SI.Angle rightQ[6];
    
    protected
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties pelvisProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Pelvis);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      ModelicaHumanBodyPArts.Segments.Pelvis pelvis(
        props=pelvisProps,
        hipCenterDistance=profile.hipCenterDistance,
        animation=animation);
    
      ModelicaHumanBodyPArts.Joints.Hip leftHip(mobility=leftHipMobility, isLeft=true,
        q_start=leftHipStart, q_fixed=fill(fixInitialJointCoordinates,3),
        w_fixed=fill(fixInitialJointVelocities,3));
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee leftKnee(mobility=leftKneeMobility,
        phi_start=leftKneeStart, phi_fixed=fixInitialJointCoordinates, w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex leftAnkle(mobility=leftAnkleMobility, isLeft=true,
        q_start=leftAnkleStart, q_fixed=fill(fixInitialJointCoordinates,2),
        w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(
        props=footProps,
        footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,
        ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole, comOffsetSourceId=footCOMOffsetSourceId,
        animation=animation,
        isLeft=true);
    
      ModelicaHumanBodyPArts.Joints.Hip rightHip(mobility=rightHipMobility, isLeft=false,
        q_start=rightHipStart, q_fixed=fill(fixInitialJointCoordinates,3),
        w_fixed=fill(fixInitialJointVelocities,3));
      ModelicaHumanBodyPArts.Segments.Thigh rightThigh(props=thighProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee rightKnee(mobility=rightKneeMobility,
        phi_start=rightKneeStart, phi_fixed=fixInitialJointCoordinates, w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank rightShank(props=shankProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex rightAnkle(mobility=rightAnkleMobility, isLeft=false,
        q_start=rightAnkleStart, q_fixed=fill(fixInitialJointCoordinates,2),
        w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(
        props=footProps,
        footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,
        ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole, comOffsetSourceId=footCOMOffsetSourceId,
        animation=animation,
        isLeft=false);
    
    equation
      leftQ = cat(1,leftHip.q,{leftKnee.q},leftAnkle.q);
      rightQ = cat(1,rightHip.q,{rightKnee.q},rightAnkle.q);
      representedMass = pelvisProps.mass + 2*(thighProps.mass+shankProps.mass+footProps.mass);
      connect(frame_pelvisProximal, pelvis.frame_proximal);
    
      connect(pelvis.frame_leftHip, leftHip.frame_a);
      connect(leftHip.frame_b, leftThigh.frame_proximal);
      connect(leftThigh.frame_distal, leftKnee.frame_a);
      connect(leftKnee.frame_b, leftShank.frame_proximal);
      connect(leftShank.frame_distal, leftAnkle.frame_a);
      connect(leftAnkle.frame_b, leftFoot.frame_ankle);
      connect(leftFoot.frame_ankle, leftFootReference);
    
      connect(pelvis.frame_rightHip, rightHip.frame_a);
      connect(rightHip.frame_b, rightThigh.frame_proximal);
      connect(rightThigh.frame_distal, rightKnee.frame_a);
      connect(rightKnee.frame_b, rightShank.frame_proximal);
      connect(rightShank.frame_distal, rightAnkle.frame_a);
      connect(rightAnkle.frame_b, rightFoot.frame_ankle);
      connect(rightFoot.frame_ankle, rightFootReference);
    
    
      for i in 1:6 loop
        connect(leftFoot.frame_plantar[i], leftPlantarFrames[i]);
        connect(rightFoot.frame_plantar[i], rightPlantarFrames[i]);
      end for;
    
      leftAnkleLimitUtilization = leftAnkle.limitUtilization;
      rightAnkleLimitUtilization = rightAnkle.limitUtilization;
      leftKneeLimitUtilization = leftKnee.limitUtilization;
      rightKneeLimitUtilization = rightKnee.limitUtilization;
      leftHipLimitUtilization = leftHip.limitUtilization;
      rightHipLimitUtilization = rightHip.limitUtilization;
    
      annotation(Documentation(info="<html>
      <p>v0.6 uses one neutral anatomical coordinate convention across pelvis, thigh,
      shank and foot. Side-aware hip/ankle axes and right-foot contact mirroring
      are applied before canonical limiting-joint studies are attempted.</p>
      </html>"));
    end LowerBodyAssembly;
  
    model LowerBodyGroundedAssembly
      "Lower body with two six-zone plantar contacts"
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter Modelica.Units.SI.Angle leftHipStart[3]=zeros(3), rightHipStart[3]=zeros(3);
      parameter Modelica.Units.SI.Angle leftKneeStart=0, rightKneeStart=0;
      parameter Modelica.Units.SI.Angle leftAnkleStart[2]=zeros(2), rightAnkleStart[2]=zeros(2);
      parameter Modelica.Units.SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftAnkleMobility(n=2)=ankleMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightAnkleMobility(n=2)=ankleMobility;
    
    
      parameter Modelica.Units.SI.Position groundHeight=0 "Horizontal world-z reporting/contact plane";
      parameter Real kNormal(unit="N/m")=2e5;
      parameter Real cNormal(unit="N.s/m")=500;
      parameter Real mu(min=0)=0.7;
      parameter Modelica.Units.SI.Velocity vSlip=0.01;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0;
      parameter Modelica.Units.SI.AngularVelocity omegaTorsionSlip=0.05;
      parameter Modelica.Units.SI.Length patchRadius[6]=fill(0,6);
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisProximal;
    
      output Modelica.Units.SI.Force leftGRF[3];
      output Modelica.Units.SI.Force rightGRF[3];
      output Modelica.Units.SI.Torque leftGroundMoment[3];
      output Modelica.Units.SI.Torque rightGroundMoment[3];
      output Modelica.Units.SI.Position leftCOP[2];
      output Modelica.Units.SI.Position rightCOP[2];
      output Boolean leftCOPValid;
      output Boolean rightCOPValid;
      output Modelica.Units.SI.Torque leftTorsionalCapacity;
      output Modelica.Units.SI.Torque rightTorsionalCapacity;
      output Real leftTorsionalUtilization;
      output Real rightTorsionalUtilization;
    
      output Modelica.Units.SI.Angle leftQ[6],rightQ[6];
      output Modelica.Units.SI.Mass representedMass;
      output Modelica.Units.SI.Position leftZonePosition[6,3],rightZonePosition[6,3];
      output Modelica.Units.SI.Force leftZoneForce[6,3],rightZoneForce[6,3];
    
    protected
      LowerBodyAssembly body(
        profile=profile,
        fixInitialJointCoordinates=fixInitialJointCoordinates,
        fixInitialJointVelocities=fixInitialJointVelocities,
        leftHipStart=leftHipStart, rightHipStart=rightHipStart,
        leftKneeStart=leftKneeStart, rightKneeStart=rightKneeStart,
        leftAnkleStart=leftAnkleStart, rightAnkleStart=rightAnkleStart,
        footCOMAboveSole=footCOMAboveSole, footCOMOffsetSourceId=footCOMOffsetSourceId,
        hipMobility=hipMobility,
        kneeMobility=kneeMobility,
        ankleMobility=ankleMobility,
        leftHipMobility=leftHipMobility,rightHipMobility=rightHipMobility,
        leftKneeMobility=leftKneeMobility,rightKneeMobility=rightKneeMobility,
        leftAnkleMobility=leftAnkleMobility,rightAnkleMobility=rightAnkleMobility);
    
      ModelicaHumanBodyPArts.Contact.PlantarContact leftContact(
        groundHeight=groundHeight,
        kNormal=kNormal, cNormal=cNormal, mu=mu, vSlip=vSlip,
        torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
      ModelicaHumanBodyPArts.Contact.PlantarContact rightContact(
        groundHeight=groundHeight,
        kNormal=kNormal, cNormal=cNormal, mu=mu, vSlip=vSlip,
        torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
    
    equation
      leftQ=body.leftQ; rightQ=body.rightQ;
      representedMass=body.representedMass;
      leftZonePosition=leftContact.zonePositionWorld;
      rightZonePosition=rightContact.zonePositionWorld;
      leftZoneForce=leftContact.zoneForceWorld;
      rightZoneForce=rightContact.zoneForceWorld;
      connect(frame_pelvisProximal, body.frame_pelvisProximal);
      connect(body.leftFootReference, leftContact.frame_torsion);
      connect(body.rightFootReference, rightContact.frame_torsion);
    
      for i in 1:6 loop
        connect(body.leftPlantarFrames[i], leftContact.plantarFrames[i]);
        connect(body.rightPlantarFrames[i], rightContact.plantarFrames[i]);
      end for;
    
      leftGRF = leftContact.groundReactionForce;
      rightGRF = rightContact.groundReactionForce;
      leftGroundMoment = leftContact.groundMoment;
      rightGroundMoment = rightContact.groundMoment;
      leftCOP = leftContact.cop;
      leftCOPValid = leftContact.copValid;
      rightCOPValid = rightContact.copValid;
      rightCOP = rightContact.cop;
      leftTorsionalCapacity = leftContact.torsionalCapacity;
      rightTorsionalCapacity = rightContact.torsionalCapacity;
      leftTorsionalUtilization = leftContact.torsionalUtilization;
      rightTorsionalUtilization = rightContact.torsionalUtilization;
    end LowerBodyGroundedAssembly;
  
  end Assemblies;

