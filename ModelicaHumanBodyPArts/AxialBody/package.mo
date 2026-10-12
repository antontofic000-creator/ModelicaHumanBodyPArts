within ModelicaHumanBodyPArts;
  package AxialBody
    "Executable pelvis-lumbar-thorax extension; independent hips remain in the lower-body assembly"
    extends Modelica.Icons.Package;

    model PelvicRing
      "Rigid pelvic ring with bilateral hip centres and a lumbosacral reference"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D props;
      parameter SI.Length hipCenterDistance(min=0);
      parameter SI.Length lumbosacralToHipVertical(min=0)
        "Inferior distance from lumbosacral frame to hip-centre level";
      parameter SI.Length displayAP(min=0)=0.18;
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_lumbosacral;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightHip;

      output SI.Force reactionForceAtLumbosacral[3]=frame_lumbosacral.f
        "Flow sign follows Modelica frame convention, resolved in local frame";
      output SI.Torque reactionMomentAtLumbosacral[3]=frame_lumbosacral.t;

    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=animation,
        r={0,0,-lumbosacralToHipVertical},
        r_CM=props.rCM,
        m=props.mass,
        I_11=props.I_CM[1,1], I_22=props.I_CM[2,2], I_33=props.I_CM[3,3],
        I_21=props.I_CM[2,1], I_31=props.I_CM[3,1], I_32=props.I_CM[3,2],
        shapeType="box",
        length=max(lumbosacralToHipVertical,1e-4),
        width=max(hipCenterDistance,1e-4),
        height=max(displayAP,1e-4),
        lengthDirection={0,0,-1}, widthDirection={0,1,0});
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation leftHip(
        r={0,0.5*hipCenterDistance,-lumbosacralToHipVertical},animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation rightHip(
        r={0,-0.5*hipCenterDistance,-lumbosacralToHipVertical},animation=false);
    equation
      assert(props.mass>0 and ModelicaHumanBodyPArts.Utilities.physicalInertia(props.I_CM),
        "PelvicRing requires positive mass and a physical COM inertia tensor.");
      connect(frame_lumbosacral,body.frame_a);
      connect(frame_lumbosacral,leftHip.frame_a);
      connect(frame_lumbosacral,rightHip.frame_a);
      connect(leftHip.frame_b,frame_leftHip);
      connect(rightHip.frame_b,frame_rightHip);
      annotation(Documentation(info="<html><p>Baseline anatomical architecture: one mostly rigid pelvic ring, not two freely rotating hemipelves. Small sacroiliac compliance is intentionally deferred to a replaceable sensitivity architecture. The mass tensor is explicit and must not overlap with thorax/abdomen mass partitions.</p></html>"));
    end PelvicRing;

    model LumbarSpine3D
      "Reduced passive 3-DOF lumbosacral joint: flexion, lateral bending, axial rotation"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3);
      parameter SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3);
      parameter Real kPassive[3](each unit="N.m/rad")={0,0,0};
      parameter Real cPassive[3](each unit="N.m.s/rad")={0,0,0};
      parameter SI.Angle qNeutral[3]={0,0,0};

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvis;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_thorax;

      output SI.Angle q[3];
      output SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output SI.Torque passiveTorque[3];
      output SI.Power passivePower;
      output SI.Force pelvisReactionForce[3]=frame_pelvis.f;
      output SI.Torque pelvisReactionMoment[3]=frame_pelvis.t;
      output SI.Force thoraxReactionForce[3]=frame_thorax.f;
      output SI.Torque thoraxReactionMoment[3]=frame_thorax.t;

    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(
        n={0,1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute lateralBend(
        n={-1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute axialRotation(
        n={0,0,1},useAxisFlange=true,
        phi(start=q_start[3],fixed=q_fixed[3]),w(start=w_start[3],fixed=w_fixed[3]));
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveFlex(
        c=kPassive[1],d=cPassive[1],phi_rel0=-qNeutral[1]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveBend(
        c=kPassive[2],d=cPassive[2],phi_rel0=-qNeutral[2]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveAxial(
        c=kPassive[3],d=cPassive[3],phi_rel0=-qNeutral[3]);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3,mobility=mobility);
    equation
      connect(frame_pelvis,flexExt.frame_a);
      connect(flexExt.frame_b,lateralBend.frame_a);
      connect(lateralBend.frame_b,axialRotation.frame_a);
      connect(axialRotation.frame_b,frame_thorax);
      connect(flexExt.axis,passiveFlex.flange_a); connect(flexExt.support,passiveFlex.flange_b);
      connect(lateralBend.axis,passiveBend.flange_a); connect(lateralBend.support,passiveBend.flange_b);
      connect(axialRotation.axis,passiveAxial.flange_a); connect(axialRotation.support,passiveAxial.flange_b);
      q={flexExt.phi,lateralBend.phi,axialRotation.phi};
      w={flexExt.w,lateralBend.w,axialRotation.w};
      monitor.q=q;
      limitUtilization=monitor.utilization;
      passiveTorque=-kPassive.*(q-qNeutral)-cPassive.*w;
      passivePower=sum(passiveTorque.*w);
      annotation(Documentation(info="<html><p>Library coordinates are +x anterior, +y left, +z superior. Positive flexion moves the superior trunk anteriorly (+y rotation axis); positive lateral bend moves it leftward (-x axis); positive axial rotation is left yaw (+z axis). No active torque is hidden here. Passive impedance is explicit and separately reported. Landmark-level ISB validation remains required before clinical interpretation.</p></html>"));
    end LumbarSpine3D;

    model Thorax
      "Rigid thoracic segment with lumbar, cervical and bilateral shoulder reference frames"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D props;
      parameter SI.Length shoulderWidth(min=0);
      parameter SI.Length shoulderHeight(min=0)=0.75*props.length;
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_lumbar;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftShoulder;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightShoulder;

      output SI.Force lumbarReactionForce[3]=frame_lumbar.f;
      output SI.Torque lumbarReactionMoment[3]=frame_lumbar.t;

    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=animation,r={0,0,props.length},r_CM=props.rCM,m=props.mass,
        I_11=props.I_CM[1,1],I_22=props.I_CM[2,2],I_33=props.I_CM[3,3],
        I_21=props.I_CM[2,1],I_31=props.I_CM[3,1],I_32=props.I_CM[3,2],
        shapeType="box",length=max(props.length,1e-4),width=max(shoulderWidth,1e-4),height=0.18,
        lengthDirection={0,0,1},widthDirection={0,1,0});
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation leftShoulder(
        r={0,0.5*shoulderWidth,shoulderHeight},animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation rightShoulder(
        r={0,-0.5*shoulderWidth,shoulderHeight},animation=false);
    equation
      assert(props.mass>0 and props.length>0 and shoulderHeight>=0 and shoulderHeight<=props.length and
        ModelicaHumanBodyPArts.Utilities.physicalInertia(props.I_CM),
        "Thorax requires positive dimensions/mass and a physical inertia tensor.");
      connect(frame_lumbar,body.frame_a);
      connect(body.frame_b,frame_cervical);
      connect(frame_lumbar,leftShoulder.frame_a); connect(leftShoulder.frame_b,frame_leftShoulder);
      connect(frame_lumbar,rightShoulder.frame_a); connect(rightShoulder.frame_b,frame_rightShoulder);
      annotation(Documentation(info="<html><p>Mass properties are explicit inputs. This component does not silently reuse the old lower-trunk/pelvis proxy. Shoulder/cervical frames are mechanical reference points, not validated anatomical landmarks.</p></html>"));
    end Thorax;

    model PelvisLumbarThorax
      "Rigid pelvic ring + passive 3-DOF lumbar joint + rigid thorax"
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter Modelica.Units.SI.Length hipCenterDistance;
      parameter Modelica.Units.SI.Length lumbosacralToHipVertical;
      parameter Modelica.Units.SI.Length shoulderWidth;
      parameter Modelica.Units.SI.Length shoulderHeight=0.75*thoraxProps.length;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Modelica.Units.SI.Angle lumbarStart[3]={0,0,0};
      parameter Boolean lumbarFixed[3]=fill(false,3);
      parameter Modelica.Units.SI.AngularVelocity lumbarWStart[3]=fill(0,3);
      parameter Boolean lumbarWFixed[3]=fill(false,3);
      parameter Real lumbarK[3](each unit="N.m/rad")={0,0,0};
      parameter Real lumbarC[3](each unit="N.m.s/rad")={0,0,0};
      parameter Modelica.Units.SI.Angle lumbarNeutral[3]={0,0,0};
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftShoulder;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightShoulder;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;

      output Modelica.Units.SI.Angle lumbarQ[3];
      output Modelica.Units.SI.AngularVelocity lumbarW[3];
      output Modelica.Units.SI.Torque lumbarPassiveTorque[3];
      output Modelica.Units.SI.Power lumbarPassivePower;
      output Modelica.Units.SI.Force lumbosacralForce[3];
      output Modelica.Units.SI.Torque lumbosacralMoment[3];
      output Modelica.Units.SI.Mass representedAxialMass=pelvicProps.mass+thoraxProps.mass;
    protected
      PelvicRing pelvis(props=pelvicProps,hipCenterDistance=hipCenterDistance,
        lumbosacralToHipVertical=lumbosacralToHipVertical,animation=animation);
      LumbarSpine3D lumbar(mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,
        w_start=lumbarWStart,w_fixed=lumbarWFixed,kPassive=lumbarK,cPassive=lumbarC,qNeutral=lumbarNeutral);
      Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
    equation
      connect(frame_pelvisReference,pelvis.frame_lumbosacral);
      connect(pelvis.frame_lumbosacral,lumbar.frame_pelvis);
      connect(lumbar.frame_thorax,thorax.frame_lumbar);
      connect(pelvis.frame_leftHip,frame_leftHip); connect(pelvis.frame_rightHip,frame_rightHip);
      connect(thorax.frame_cervical,frame_cervical);
      connect(thorax.frame_leftShoulder,frame_leftShoulder); connect(thorax.frame_rightShoulder,frame_rightShoulder);
      lumbarQ=lumbar.q; lumbarW=lumbar.w; lumbarPassiveTorque=lumbar.passiveTorque;
      lumbarPassivePower=lumbar.passivePower;
      lumbosacralForce=lumbar.pelvisReactionForce; lumbosacralMoment=lumbar.pelvisReactionMoment;
    end PelvisLumbarThorax;

    model LowerBodyAxialAssembly
      "Bilateral legs connected to the new rigid pelvic ring and articulated lumbar/thorax chain"
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
      parameter Real hipK[3](each unit="N.m/rad")={0,0,0};
      parameter Real hipC[3](each unit="N.m.s/rad")={0,0,0};
      parameter SI.Angle hipNeutral[3]={0,0,0};
      parameter Real lumbarK[3](each unit="N.m/rad")={0,0,0};
      parameter Real lumbarC[3](each unit="N.m.s/rad")={0,0,0};
      parameter SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightFootReference;

      output SI.Mass representedMass;
      output SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output SI.Force leftHipReactionForce[3],rightHipReactionForce[3];
      output SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3];
      output SI.Force leftKneeReactionForce[3],rightKneeReactionForce[3];
      output SI.Torque leftKneeReactionMoment[3],rightKneeReactionMoment[3];
      output SI.Force leftAnkleReactionForce[3],rightAnkleReactionForce[3];
      output SI.Torque leftAnkleReactionMoment[3],rightAnkleReactionMoment[3];
      output SI.Force lumbosacralForce[3];
      output SI.Torque lumbosacralMoment[3];
      output SI.Power lumbarPassivePower;

    protected
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      PelvisLumbarThorax axial(pelvicProps=pelvicProps,thoraxProps=thoraxProps,
        hipCenterDistance=profile.hipCenterDistance,lumbosacralToHipVertical=lumbosacralToHipVertical,
        shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,lumbarMobility=lumbarMobility,
        lumbarStart=lumbarStart,lumbarFixed=lumbarFixed,lumbarWStart=lumbarWStart,lumbarWFixed=lumbarWFixed,
        lumbarK=lumbarK,lumbarC=lumbarC,animation=animation);
      ModelicaHumanBodyPArts.Joints.Hip leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,
        q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),
        kPassive=hipK,cPassive=hipC,qNeutral=hipNeutral);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,
        phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,
        q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Joints.Hip rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,
        q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),
        kPassive=hipK,cPassive=hipC,qNeutral=hipNeutral);
      ModelicaHumanBodyPArts.Segments.Thigh rightThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,
        phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank rightShank(props=shankProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,
        q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
      connect(frame_pelvisReference,axial.frame_pelvisReference); connect(axial.frame_cervical,frame_cervical);
      connect(axial.frame_leftHip,leftHip.frame_a); connect(leftHip.frame_b,leftThigh.frame_proximal);
      connect(leftThigh.frame_distal,leftKnee.frame_a); connect(leftKnee.frame_b,leftShank.frame_proximal);
      connect(leftShank.frame_distal,leftAnkle.frame_a); connect(leftAnkle.frame_b,leftFoot.frame_ankle);
      connect(leftFoot.frame_ankle,leftFootReference);
      connect(axial.frame_rightHip,rightHip.frame_a); connect(rightHip.frame_b,rightThigh.frame_proximal);
      connect(rightThigh.frame_distal,rightKnee.frame_a); connect(rightKnee.frame_b,rightShank.frame_proximal);
      connect(rightShank.frame_distal,rightAnkle.frame_a); connect(rightAnkle.frame_b,rightFoot.frame_ankle);
      connect(rightFoot.frame_ankle,rightFootReference);
      for i in 1:6 loop
        connect(leftFoot.frame_plantar[i],leftPlantarFrames[i]); connect(rightFoot.frame_plantar[i],rightPlantarFrames[i]);
      end for;
      leftQ=cat(1,leftHip.q,{leftKnee.q},leftAnkle.q); rightQ=cat(1,rightHip.q,{rightKnee.q},rightAnkle.q);
      lumbarQ=axial.lumbarQ;
      representedMass=pelvicProps.mass+thoraxProps.mass+2*(thighProps.mass+shankProps.mass+footProps.mass);
      leftHipReactionForce=leftHip.frame_a.f; rightHipReactionForce=rightHip.frame_a.f;
      leftHipReactionMoment=leftHip.frame_a.t; rightHipReactionMoment=rightHip.frame_a.t;
      leftKneeReactionForce=leftKnee.frame_a.f; rightKneeReactionForce=rightKnee.frame_a.f;
      leftKneeReactionMoment=leftKnee.frame_a.t; rightKneeReactionMoment=rightKnee.frame_a.t;
      leftAnkleReactionForce=leftAnkle.frame_a.f; rightAnkleReactionForce=rightAnkle.frame_a.f;
      leftAnkleReactionMoment=leftAnkle.frame_a.t; rightAnkleReactionMoment=rightAnkle.frame_a.t;
      lumbosacralForce=axial.lumbosacralForce; lumbosacralMoment=axial.lumbosacralMoment;
      lumbarPassivePower=axial.lumbarPassivePower;
      annotation(Documentation(info="<html><p>This assembly replaces the old pelvis/lower-trunk proxy with explicit pelvic-ring and thorax mass tensors separated by a 3-DOF lumbar joint. It does not yet generate those axial mass properties from stature; they are explicit source-traceable inputs.</p></html>"));
    end LowerBodyAxialAssembly;

    model LowerBodyAxialGroundedAssembly
      "Axial-body lower-body assembly with two six-zone plantar contacts"
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter Modelica.Units.SI.Length lumbosacralToHipVertical;
      parameter Modelica.Units.SI.Length shoulderWidth;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Real hipK[3](each unit="N.m/rad")={0,0,0};
      parameter Real hipC[3](each unit="N.m.s/rad")={0,0,0};
      parameter Modelica.Units.SI.Angle hipNeutral[3]={0,0,0};
      parameter Real lumbarK[3](each unit="N.m/rad")={0,0,0};
      parameter Real lumbarC[3](each unit="N.m.s/rad")={0,0,0};
      parameter Modelica.Units.SI.Position groundHeight=0;
      parameter Real kNormal(unit="N/m")=2e5;
      parameter Real cNormal(unit="N.s/m")=500;
      parameter Real mu(min=0)=0.7;
      parameter Modelica.Units.SI.Velocity vSlip=0.01;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0;
      parameter Modelica.Units.SI.AngularVelocity omegaTorsionSlip=0.05;
      parameter Modelica.Units.SI.Length patchRadius[6]=fill(0,6);

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      output Modelica.Units.SI.Force leftGRF[3],rightGRF[3];
      output Modelica.Units.SI.Torque leftGroundMoment[3],rightGroundMoment[3];
      output Modelica.Units.SI.Position leftCOP[2],rightCOP[2];
      output Boolean leftCOPValid,rightCOPValid;
      output Modelica.Units.SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output Modelica.Units.SI.Mass representedMass;
      output Modelica.Units.SI.Force leftHipReactionForce[3],rightHipReactionForce[3];
      output Modelica.Units.SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3];
      output Modelica.Units.SI.Torque lumbosacralMoment[3];
    protected
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pelvicProps,thoraxProps=thoraxProps,
        lumbosacralToHipVertical=lumbosacralToHipVertical,shoulderWidth=shoulderWidth,
        hipMobility=hipMobility,kneeMobility=kneeMobility,ankleMobility=ankleMobility,
        lumbarMobility=lumbarMobility,hipK=hipK,hipC=hipC,hipNeutral=hipNeutral,lumbarK=lumbarK,lumbarC=lumbarC);
      ModelicaHumanBodyPArts.Contact.PlantarContact leftContact(groundHeight=groundHeight,kNormal=kNormal,
        cNormal=cNormal,mu=mu,vSlip=vSlip,torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
      ModelicaHumanBodyPArts.Contact.PlantarContact rightContact(groundHeight=groundHeight,kNormal=kNormal,
        cNormal=cNormal,mu=mu,vSlip=vSlip,torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
    equation
      connect(frame_pelvisReference,body.frame_pelvisReference); connect(body.frame_cervical,frame_cervical);
      connect(body.leftFootReference,leftContact.frame_torsion); connect(body.rightFootReference,rightContact.frame_torsion);
      for i in 1:6 loop
        connect(body.leftPlantarFrames[i],leftContact.plantarFrames[i]); connect(body.rightPlantarFrames[i],rightContact.plantarFrames[i]);
      end for;
      leftGRF=leftContact.groundReactionForce; rightGRF=rightContact.groundReactionForce;
      leftGroundMoment=leftContact.groundMoment; rightGroundMoment=rightContact.groundMoment;
      leftCOP=leftContact.cop; rightCOP=rightContact.cop; leftCOPValid=leftContact.copValid; rightCOPValid=rightContact.copValid;
      leftQ=body.leftQ; rightQ=body.rightQ; lumbarQ=body.lumbarQ; representedMass=body.representedMass;
      leftHipReactionForce=body.leftHipReactionForce; rightHipReactionForce=body.rightHipReactionForce;
      leftHipReactionMoment=body.leftHipReactionMoment; rightHipReactionMoment=body.rightHipReactionMoment;
      lumbosacralMoment=body.lumbosacralMoment;
    end LowerBodyAxialGroundedAssembly;

    model PelvicRingGeometryTest
      "Synthetic geometry regression for rigid pelvic ring and bilateral hip frames"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D p(mass=8,length=0.18,rCM={0,0,-0.05},
        I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,1.1},animation=false);
      PelvicRing pelvis(props=p,hipCenterDistance=0.20,lumbosacralToHipVertical=0.10,animation=false);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition leftPos(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition rightPos(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.009;
    equation
      connect(anchor.frame_b,pelvis.frame_lumbosacral); connect(pelvis.frame_leftHip,leftPos.frame_a); connect(pelvis.frame_rightHip,rightPos.frame_a);
    algorithm
      when time>=verificationTime then
        assert(abs(leftPos.r[2]-0.10)<1e-10 and abs(rightPos.r[2]+0.10)<1e-10,"Pelvic hip lateral symmetry failed");
        assert(abs(leftPos.r[3]-1.0)<1e-10 and abs(rightPos.r[3]-1.0)<1e-10,"Pelvic hip level failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end PelvicRingGeometryTest;

    model LumbarAxisGeometryTest
      "Independent prescribed-axis geometry check for the three lumbar coordinates"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter Real cases[3,3]={{0.15,0,0},{0,0.15,0},{0,0,0.15}};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[3](each r={0,0,1},each animation=false);
      LumbarSpine3D lumbar[3](each mobility=rom,q_start=cases,
        each q_fixed={true,true,true},each w_fixed={true,true,true});
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation marker[3](each r={0.10,0,0.40},each animation=false);
      Modelica.Mechanics.MultiBody.Parts.Body testInertia[3](each animation=false,
        each m=1,each r_CM={0,0,0},each I_11=0.01,each I_22=0.01,each I_33=0.01)
        "Finite inertial fixture removes the massless zero-impedance indeterminacy";
      output Real observed[3,3];
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.009;
    equation
      for i in 1:3 loop
        connect(anchor[i].frame_b,lumbar[i].frame_pelvis); connect(lumbar[i].frame_thorax,marker[i].frame_a);
        connect(marker[i].frame_b,testInertia[i].frame_a);
        observed[i,:]=marker[i].frame_b.r_0-anchor[i].r;
      end for;
    algorithm
      when time>=verificationTime then
        assert(observed[1,1]>0.10,"Positive lumbar flexion must move superior marker anteriorly");
        assert(observed[2,2]>0,"Positive lateral bend must move superior marker leftward");
        assert(observed[3,2]>0,"Positive axial rotation must rotate anterior marker toward leftward +y");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end LumbarAxisGeometryTest;

    model AxialMassPartitionTest
      "Synthetic check that pelvis and thorax masses are distinct and counted once"
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.50,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      output Modelica.Units.SI.Mass axialMass=pp.mass+tp.mass;
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.009;
    algorithm
      when time>=verificationTime then
        assert(abs(axialMass-33)<1e-12,"Axial mass partition double-count/missing-mass test failed"); checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end AxialMassPartitionTest;

    model LumbarPassiveDissipationTest
      "Synthetic passive axial-rotation decay; verifies no hidden propulsive torque"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=10,length=0.40,rCM={0,0,0.20},I_CM={{0.5,0,0},{0,0.5,0},{0,0,0.25}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed base(animation=false);
      LumbarSpine3D lumbar(mobility=rom,q_start={0,0,0.20},q_fixed={true,true,true},w_start={0,0,0},w_fixed={true,true,true},kPassive={0,0,20},cPassive={0,0,1});
      Thorax thorax(props=tp,shoulderWidth=0.40,animation=false);
      output SI.Angle axialAngle=lumbar.q[3];
      output SI.Power passivePower=lumbar.passivePower;
      output Integer checksPassed(start=0,fixed=true);
      parameter SI.Time verificationTime=1.0;
    equation
      connect(base.frame_b,lumbar.frame_pelvis); connect(lumbar.frame_thorax,thorax.frame_lumbar);
    algorithm
      when time>=verificationTime then
        assert(abs(axialAngle)<0.20,"Passive lumbar spring/damper did not reduce initial axial displacement");
        assert(passivePower<=1e-6,"Passive lumbar element generated positive mechanical power at verification time");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1.1,Tolerance=1e-8,Interval=0.001));
    end LumbarPassiveDissipationTest;

    model LowerBodyAxialAssemblyBuild
      "Build-only fixture for the new axial lower-body architecture"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.50,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-0.5,-0.5,-0.5},qMax={0.5,0.5,0.5},sourceId="SYNTHETIC_AXIAL_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,1.1},animation=false);
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.10,shoulderWidth=0.40,
        hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},animation=false);
    equation
      connect(anchor.frame_b,body.frame_pelvisReference);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyAxialAssemblyBuild;


    model StandingLegRotationalTransmissionTest
      "External standing-foot yaw torque; pelvis/lumbar/free-hip responses are outputs, not prescribed"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,
        shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(
        mass=8,length=0.18,rCM={0,0,-0.05},
        I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(
        mass=25,length=0.50,rCM={0,0,0.25},
        I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-1},qMax={2.8},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(
        n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed ground(animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute standingYaw(
        n={0,0,1},useAxisFlange=true,phi(start=0,fixed=true),w(start=0,fixed=true));
      Modelica.Mechanics.Rotational.Sources.Torque torqueSource(useSupport=true);
      LowerBodyAxialAssembly body(
        profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.10,shoulderWidth=0.40,
        hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,
        hipK={0,0,25},hipC={0,0,1.2},lumbarK={0,0,15},lumbarC={0,0,0.8},
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      output SI.Torque appliedGroundTorque;
      output SI.Angle standingFootYaw=standingYaw.phi;
      output SI.Angle standingHipAxial=body.leftQ[3];
      output SI.Angle freeHipAxial=body.rightQ[3];
      output SI.Angle pelvisYawProxy=standingFootYaw+standingHipAxial
        "Exact for the test's axial chain because ankle/knee have no yaw DOF";
      output SI.Angle lumbarAxial=body.lumbarQ[3];
      output SI.Angle thoraxYawProxy=pelvisYawProxy+lumbarAxial;
      output SI.Torque standingHipReactionYaw=body.leftHipReactionMoment[3];
      output SI.Torque lumbosacralReactionYaw=body.lumbosacralMoment[3];
      output Integer checksPassed(start=0,fixed=true);
      parameter SI.Time verificationTime=0.45;
    equation
      connect(ground.frame_b,standingYaw.frame_a);
      connect(standingYaw.frame_b,body.leftPlantarFrames[1]);
      connect(torqueSource.flange,standingYaw.axis);
      connect(torqueSource.support,standingYaw.support);
      appliedGroundTorque=if time<0.05 then 0 else if time<0.25 then 5 else 0;
      torqueSource.tau=appliedGroundTorque;
    algorithm
      when time>=verificationTime then
        assert(abs(standingFootYaw)>1e-6,"Standing-foot yaw did not respond to the external torque.");
        assert(abs(pelvisYawProxy)>1e-6,"No rotational response reached the pelvis proxy.");
        assert(abs(lumbarAxial)>1e-7,"No rotational response reached the lumbar coordinate.");
        assert(abs(freeHipAxial)>1e-7,"No rotational response reached the opposite/free hip.");
        checksPassed:=1;
      end when;
      annotation(Documentation(info="<html><p>This is a synthetic mechanical transmission test, not a Lynkorr proof. The only imposed rotational mission profile is the standing-foot external torque. Pelvis proxy, lumbar axial rotation and opposite-hip rotation are measured outputs. The signs/magnitudes are not prescribed and must not be interpreted as human data because the passive stiffness/damping values and axial mass tensors are synthetic.</p></html>"),
        experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.0005));
    end StandingLegRotationalTransmissionTest;

  end AxialBody;



