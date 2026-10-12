within ModelicaHumanBodyPArts;
  package Tests
    extends Modelica.Icons.ExamplesPackage;
  
    model NeutralStanceGeometryTest
      "Coordinate regression: neutral leg/foot geometry, side mirroring, hip-flexion sign"
      import SI = Modelica.Units.SI;
    
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity);
    
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75,
        mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,
        footWidth=0.095,
        ankleFromHeel=0.07,
        ankleHeight=0.08,
        shankLength=0.43,
        thighLength=0.44,
        pelvisLength=0.18,
        hipCenterDistance=0.20);
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3, qMin={-1,-1,-1}, qMax={2,1,1}, sourceId="TEST_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1, qMin={-0.2}, qMax={2.8}, sourceId="TEST_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2, qMin={-1,-1}, qMax={1,1}, sourceId="TEST_ONLY");
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      parameter SI.Angle hipFlex = Modelica.Units.Conversions.from_deg(10);
    
      // Neutral left leg: every initial joint coordinate is fixed at zero only for this regression test.
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedNeutralHip(r={0,0,1.0});
      ModelicaHumanBodyPArts.Joints.Hip neutralHip(
        mobility=hipROM, q_start={0,0,0}, q_fixed={true,true,true}, w_fixed={true,true,true}, isLeft=true);
      ModelicaHumanBodyPArts.Segments.Thigh neutralThigh(props=thighProps, animation=false);
      ModelicaHumanBodyPArts.Joints.Knee neutralKnee(
        mobility=kneeROM, phi_start=0, phi_fixed=true, w_fixed=true);
      ModelicaHumanBodyPArts.Segments.Shank neutralShank(props=shankProps, animation=false);
      ModelicaHumanBodyPArts.Joints.AnkleComplex neutralAnkle(
        mobility=ankleROM, q_start={0,0}, q_fixed={true,true}, w_fixed={true,true}, isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot neutralFoot(
        props=footProps, footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel, ankleHeight=profile.ankleHeight,
        animation=false, isLeft=true);
    
      // Positive hip-flexion chain.
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedFlexHip(r={0,0,1.0});
      ModelicaHumanBodyPArts.Joints.Hip flexedHip(
        mobility=hipROM, q_start={hipFlex,0,0}, q_fixed={true,true,true}, w_fixed={true,true,true}, isLeft=
        true);
      ModelicaHumanBodyPArts.Segments.Thigh flexedThigh(props=thighProps, animation=false);
    
      // Isolated right foot to verify medial/lateral mirroring.
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedRightAnkle(r={0,-0.20,0.20});
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(
        props=footProps, footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel, ankleHeight=profile.ankleHeight,
        animation=false, isLeft=false);
    
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition neutralKneePos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition neutralAnklePos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition heelPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition forefootPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition flexKneePos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition leftMedialPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition leftLateralPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition rightMedialPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition rightLateralPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
    
      output Real observedKneeZ=neutralKneePos.r[3];
      output Real observedAnkleZ=neutralAnklePos.r[3];
      output Real observedHeelZ=heelPos.r[3];
      output Real observedFlexX=flexKneePos.r[1];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(fixedNeutralHip.frame_b, neutralHip.frame_a);
      connect(neutralHip.frame_b, neutralThigh.frame_proximal);
      connect(neutralThigh.frame_distal, neutralKnee.frame_a);
      connect(neutralKnee.frame_b, neutralShank.frame_proximal);
      connect(neutralShank.frame_distal, neutralAnkle.frame_a);
      connect(neutralAnkle.frame_b, neutralFoot.frame_ankle);
    
      connect(neutralThigh.frame_distal, neutralKneePos.frame_a);
      connect(neutralFoot.frame_ankle, neutralAnklePos.frame_a);
      connect(neutralFoot.frame_plantar[1], heelPos.frame_a);
      connect(neutralFoot.frame_plantar[5], forefootPos.frame_a);
      connect(neutralFoot.frame_plantar[1], leftMedialPos.frame_a);
      connect(neutralFoot.frame_plantar[2], leftLateralPos.frame_a);
    
      connect(fixedFlexHip.frame_b, flexedHip.frame_a);
      connect(flexedHip.frame_b, flexedThigh.frame_proximal);
      connect(flexedThigh.frame_distal, flexKneePos.frame_a);
    
      connect(fixedRightAnkle.frame_b, rightFoot.frame_ankle);
      connect(rightFoot.frame_plantar[1], rightMedialPos.frame_a);
      connect(rightFoot.frame_plantar[2], rightLateralPos.frame_a);
    
    initial equation
      assert(neutralKneePos.r[3] < fixedNeutralHip.r[3],
        "Neutral stance failed: knee must be inferior to hip.");
      assert(heelPos.r[3] < neutralAnklePos.r[3],
        "Neutral stance failed: plantar/heel point must be inferior to ankle.");
      assert(forefootPos.r[1] > heelPos.r[1],
        "Neutral stance failed: forefoot/toe direction must be anterior to heel.");
      assert(flexKneePos.r[1] > fixedFlexHip.r[1],
        "Hip-axis mapping failed: positive hip flexion must move knee anteriorly.");
      assert(leftMedialPos.r[2] < leftLateralPos.r[2],
        "Left-foot medial/lateral zone order failed.");
      assert(rightMedialPos.r[2] > rightLateralPos.r[2],
        "Right-foot medial/lateral zone mirror failed.");
    
    
    algorithm
      when time>=verificationTime then
        assert(neutralKneePos.r[3] < fixedNeutralHip.r[3],
        "Neutral stance failed: knee must be inferior to hip.");
        assert(heelPos.r[3] < neutralAnklePos.r[3],
        "Neutral stance failed: plantar/heel point must be inferior to ankle.");
        assert(forefootPos.r[1] > heelPos.r[1],
        "Neutral stance failed: forefoot/toe direction must be anterior to heel.");
        assert(flexKneePos.r[1] > fixedFlexHip.r[1],
        "Hip-axis mapping failed: positive hip flexion must move knee anteriorly.");
        assert(leftMedialPos.r[2] < leftLateralPos.r[2],
        "Left-foot medial/lateral zone order failed.");
        assert(rightMedialPos.r[2] > rightLateralPos.r[2],
        "Right-foot medial/lateral zone mirror failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01, Tolerance=1e-8));
    end NeutralStanceGeometryTest;
  
    model HipAxisGeometryTest
      "Bilateral individual hip axes and combined serial order, using an off-axis marker"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter Real qCase[8,3]={{0.20000000000000001,0,0},{0,0.14999999999999999,0},{0,0,0.25},
        {0.20000000000000001,0.14999999999999999,0.25},{0.20000000000000001,0,0},{0,0.14999999999999999,0},
        {0,0,0.25},{0.20000000000000001,0.14999999999999999,0.25}};
      parameter Boolean sides[8]={true,true,true,true,false,false,false,false};
      parameter Real expectedKnee[8,3]={{0.087414505549826937,0,-0.43122929425014633},{0,
        -0.065752778288383662,-0.43505927429185859},{0,0,-0.44},{0.086432934879748527,-0.065752778288383662,
        -0.4263870541133159},{0.087414505549826937,0,-0.43122929425014633},{0,0.065752778288383662,
        -0.43505927429185859},{0,0,-0.44},{0.086432934879748527,0.065752778288383662,-0.4263870541133159}};
      parameter Real expectedMarker[8,3]={{0.18542116333395109,0,-0.41136236117064018},{0.10000000000000001,
        -0.065752778288383662,-0.43505927429185859},{0.096891242171064484,-0.024740395925452296,-0.44},
        {0.18065829099942585,-0.090215366236157585,-0.4035142743299705},{0.18542116333395109,0,
        -0.41136236117064018},{0.10000000000000001,0.065752778288383662,-0.43505927429185859},
        {0.096891242171064484,0.024740395925452296,-0.44},{0.18065829099942585,0.090215366236157585,
        -0.4035142743299705}};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[8](each r={0,0,1},each animation=false);
      ModelicaHumanBodyPArts.Joints.Hip hip[8](each mobility=hipROM,q_start=qCase,
        each q_fixed={true,true,true},each w_fixed={true,true,true},isLeft=sides);
      ModelicaHumanBodyPArts.Segments.Thigh thigh[8](each props=thighProps,each animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation marker[8](each r={0.1,0,-0.44},each animation=
        false);
      output Real observedKnee[8,3];
      output Real observedMarker[8,3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:8 loop
        connect(anchor[i].frame_b,hip[i].frame_a);
        connect(hip[i].frame_b,thigh[i].frame_proximal);
        connect(hip[i].frame_b,marker[i].frame_a);
        observedKnee[i,:]=thigh[i].frame_distal.r_0-anchor[i].r;
        observedMarker[i,:]=marker[i].frame_b.r_0-anchor[i].r;
      end for;
    initial equation
      assert(max(abs(observedKnee-expectedKnee))<1e-8,"Hip endpoint geometry failed.");
      assert(max(abs(observedMarker-expectedMarker))<1e-8,"Hip axial/combined-order marker failed.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedKnee-expectedKnee))<1e-8,"Hip endpoint geometry failed.");
        assert(max(abs(observedMarker-expectedMarker))<1e-8,"Hip axial/combined-order marker failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end HipAxisGeometryTest;
  
    model KneeAxisGeometryTest
      "Positive knee flexion sends the distal ankle posteriorly in the declared frame"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      ModelicaHumanBodyPArts.Joints.Knee knee(mobility=kneeROM,phi_start=0.2,phi_fixed=true,w_fixed=true);
      ModelicaHumanBodyPArts.Segments.Shank shank(props=shankProps,animation=false);
      output Real observedX=shank.frame_distal.r_0[1];
      output Real observedZ=shank.frame_distal.r_0[3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(world.frame_b,knee.frame_a);
      connect(knee.frame_b,shank.frame_proximal);
    initial equation
      assert(abs(observedX+0.43*sin(0.2))<1e-8 and abs(observedZ+0.43*cos(0.2))<1e-8,
        "Knee flexion direction/geometry failed.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(observedX+0.43*sin(0.2))<1e-8 and abs(observedZ+0.43*cos(0.2))<1e-8,
        "Knee flexion direction/geometry failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end KneeAxisGeometryTest;
  
    model AnkleAxisGeometryTest
      "Nonzero bilateral dorsiflexion/inversion and serial-order geometry; no landmark validation"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      parameter Real qCase[6,2]={{0.20000000000000001,0},{0,0.14999999999999999},{0.20000000000000001,
        0.14999999999999999},{0.20000000000000001,0},{0,0.14999999999999999},{0.20000000000000001,
        0.14999999999999999}};
      parameter Boolean sides[6]={true,true,true,false,false,false};
      parameter Real expectedToe[6,3]={{0.20210619625344078,0,-0.040658153376237696},{0.19,
        -0.011955050597887937,-0.079101686234883381},{0.20192772885888108,-0.011955050597887937,
        -0.039777746078632173},{0.20210619625344078,0,-0.040658153376237696},{0.19,0.011955050597887937,
        -0.079101686234883381},{0.20192772885888108,0.011955050597887937,-0.039777746078632173}};
      parameter Real expectedMedial[6,3]={{0.11292013766988783,-0.02375,-0.058737062478588273},
        {0.099000000000000005,-0.035438363698868942,-0.075552530588635397},{0.11203656189820052,
        -0.035438363698868942,-0.054378246352538566},{0.11292013766988783,0.02375,-0.058737062478588273},
        {0.099000000000000005,0.035438363698868942,-0.075552530588635397},{0.11203656189820052,
        0.035438363698868942,-0.054378246352538566}};
      parameter Real expectedLateral[6,3]={{0.11292013766988783,0.02375,-0.058737062478588273},
        {0.099000000000000005,0.011528262503093066,-0.082650841881131365},{0.11344677865245571,
        0.011528262503093066,-0.061335064009426919},{0.11292013766988783,-0.02375,-0.058737062478588273},
        {0.099000000000000005,-0.011528262503093066,-0.082650841881131365},{0.11344677865245571,
        -0.011528262503093066,-0.061335064009426919}};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[6](each r={0,0,0.2},each animation=false);
      ModelicaHumanBodyPArts.Joints.AnkleComplex ankle[6](each mobility=ankleROM,
        q_start=qCase,each q_fixed={true,true},each w_fixed={true,true},isLeft=sides);
      ModelicaHumanBodyPArts.Segments.Foot foot[6](each props=footProps,each footWidth=0.095,
        each ankleFromHeel=0.07,each ankleHeight=0.08,each animation=false,isLeft=sides);
      output Real observedToe[6,3];
      output Real observedMedial[6,3];
      output Real observedLateral[6,3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:6 loop
        connect(anchor[i].frame_b,ankle[i].frame_a);
        connect(ankle[i].frame_b,foot[i].frame_ankle);
        observedToe[i,:]=foot[i].frame_toe.r_0-anchor[i].r;
        observedMedial[i,:]=foot[i].frame_medial.r_0-anchor[i].r;
        observedLateral[i,:]=foot[i].frame_lateral.r_0-anchor[i].r;
      end for;
    initial equation
      assert(max(abs(observedToe-expectedToe))<1e-8,"Ankle toe geometry/rotation order failed.");
      assert(max(abs(observedMedial-expectedMedial))<1e-8,"Ankle medial geometry failed.");
      assert(max(abs(observedLateral-expectedLateral))<1e-8,"Ankle lateral geometry failed.");
      assert(observedToe[1,3]>-0.08 and observedToe[4,3]>-0.08,"Positive dorsiflexion must raise toe.");
      assert(observedMedial[2,3]>observedLateral[2,3] and observedMedial[5,3]>observedLateral[5,3],
        "Positive inversion must raise medial border on both sides.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedToe-expectedToe))<1e-8,"Ankle toe geometry/rotation order failed.");
        assert(max(abs(observedMedial-expectedMedial))<1e-8,"Ankle medial geometry failed.");
        assert(max(abs(observedLateral-expectedLateral))<1e-8,"Ankle lateral geometry failed.");
        assert(observedToe[1,3]>-0.08 and observedToe[4,3]>-0.08,"Positive dorsiflexion must raise toe.");
        assert(observedMedial[2,3]>observedLateral[2,3] and observedMedial[5,3]>observedLateral[5,3],
        "Positive inversion must raise medial border on both sides.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end AnkleAxisGeometryTest;
  
    model ContactPointCompressionTest
      "Synthetic fixed-point test of the v0.3 unilateral normal contact law"
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1});
    
      parameter Real k(unit="N/m")=100000;
      parameter Modelica.Units.SI.Length delta=0.001;
    
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedPoint(r={0,0,-delta});
      ModelicaHumanBodyPArts.Contact.ContactPoint contact(
        kNormal=k,
        cNormal=0,
        mu=0);
    
      output Real observedForce=contact.normalForce;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial equation
      assert(abs(contact.normalForce - k*delta) < 1e-6,
        "Static compression contact-force check failed.");
    
    equation
      connect(fixedPoint.frame_b, contact.frame_contact);
    
    
    algorithm
      when time>=verificationTime then
        assert(abs(contact.normalForce - k*delta) < 1e-6,
        "Static compression contact-force check failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01));
    end ContactPointCompressionTest;
  
    model ContactPointSeparationTest
      "No attractive contact force above the plane or at exact zero penetration"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
    
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[2](r={{0,0,0.31},{0,0,0.30}},each animation=false);
      ModelicaHumanBodyPArts.Contact.ContactPoint contact[2](each groundHeight=0.3);
      output Real observedForce[2]={contact[1].normalForce,contact[2].normalForce};
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:2 loop
        connect(anchor[i].frame_b,contact[i].frame_contact);
        assert(contact[i].normalForce==0 and not contact[i].active,
        "Separated/touch-only contact must carry no load.");
      end for;
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedForce))<1e-12,"Separated force nonzero at check event.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end ContactPointSeparationTest;
  
    model GroundWrenchCOPTest
      "Analytic COP / force-moment balance check"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor w(nZones=3);
    
      output Real observedFz=w.resultantForce[3];
      output Real observedMy=w.resultantMoment[2];
      output Real observedCOPx=w.cop[1];
      output Real observedCOPy=w.cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      w.rWorld = {
        {-0.10,0,0},
        { 0.00,0,0},
        { 0.10,0,0}};
    
      w.forceWorld = {
        {0,0,200},
        {0,0,300},
        {0,0,500}};
    
      w.freeMomentWorld = fill(0,3,3);
    
    initial equation
      assert(abs(w.resultantForce[3] - 1000) < 1e-10,
        "Ground reaction vertical-force sum failed.");
      assert(abs(w.resultantMoment[2] + 30) < 1e-10,
        "Ground moment My check failed.");
      assert(abs(w.cop[1] - 0.03) < 1e-10,
        "COP x check failed.");
      assert(abs(w.cop[2]) < 1e-10,
        "COP y check failed.");
    
    
    algorithm
      when time>=verificationTime then
        assert(abs(w.resultantForce[3] - 1000) < 1e-10,
        "Ground reaction vertical-force sum failed.");
        assert(abs(w.resultantMoment[2] + 30) < 1e-10,
        "Ground moment My check failed.");
        assert(abs(w.cop[1] - 0.03) < 1e-10,
        "COP x check failed.");
        assert(abs(w.cop[2]) < 1e-10,
        "COP y check failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01));
    end GroundWrenchCOPTest;
  
    model GroundWrenchCOPReferencePointTest
      "Analytic test that COP is reported in world coordinates for a nonzero reference point"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor wrench(
        nZones=1,
        referencePoint={1.0,2.0,0.0});
    
      output Real observedX=wrench.cop[1];
      output Real observedY=wrench.cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      wrench.rWorld = [1.20, 1.90, 0.0];
      wrench.forceWorld = [0.0, 0.0, 100.0];
      wrench.freeMomentWorld = [0.0, 0.0, 0.0];
    
      assert(abs(wrench.cop[1] - 1.20) < 1e-10,
        "COP x must include reference-point offset.");
      assert(abs(wrench.cop[2] - 1.90) < 1e-10,
        "COP y must include reference-point offset.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(wrench.cop[1] - 1.20) < 1e-10,
        "COP x must include reference-point offset.");
        assert(abs(wrench.cop[2] - 1.90) < 1e-10,
        "COP y must include reference-point offset.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end GroundWrenchCOPReferencePointTest;
  
    model GroundWrenchPlaneHeightTest
      "Oblique loading must give the same physical COP at different wrench reference heights"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor sensor(
        nZones=1,referencePoint={0.3,-0.2,0.4},contactPlaneHeight=0);
      output Real observedX=sensor.cop[1];
      output Real observedY=sensor.cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      sensor.rWorld=[0.02,-0.03,0];
      sensor.forceWorld=[60,-30,600];
      sensor.freeMomentWorld=zeros(1,3);
      assert(sensor.copValid and abs(sensor.cop[1]-0.02)<1e-10 and
        abs(sensor.cop[2]+0.03)<1e-10, "Reporting-height COP regression failed.");
    
    algorithm
      when time>=verificationTime then
        assert(sensor.copValid and abs(sensor.cop[1]-0.02)<1e-10 and
        abs(sensor.cop[2]+0.03)<1e-10, "Reporting-height COP regression failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end GroundWrenchPlaneHeightTest;
  
    model GroundWrenchElevatedPlaneTest
      "COP invariance across horizontal-plane/reporting-point heights under oblique load"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor a(nZones=1,referencePoint={0,0,0},
        contactPlaneHeight=0.3);
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor b(nZones=1,referencePoint={0.7,-0.4,0.8},
        contactPlaneHeight=0.3);
      output Real observedA[2]=a.cop;
      output Real observedB[2]=b.cop;
      output Real observedResidualYaw=a.freeMomentAtCOP;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      a.rWorld=[0.1,-0.2,0.3]; a.forceWorld=[40,-20,200]; a.freeMomentWorld=[0,0,3];
      b.rWorld=a.rWorld; b.forceWorld=a.forceWorld; b.freeMomentWorld=a.freeMomentWorld;
      assert(a.copValid and b.copValid and max(abs(a.cop-{0.1,-0.2}))<1e-10,
        "Elevated-plane COP reference failed.");
      assert(max(abs(a.cop-b.cop))<1e-10 and abs(a.freeMomentAtCOP-3)<1e-10,
        "Wrench relocation/residual yaw failed.");
    
    algorithm
      when time>=verificationTime then
        assert(a.copValid and b.copValid and max(abs(a.cop-{0.1,-0.2}))<1e-10,
        "Elevated-plane COP reference failed.");
        assert(max(abs(a.cop-b.cop))<1e-10 and abs(a.freeMomentAtCOP-3)<1e-10,
        "Wrench relocation/residual yaw failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end GroundWrenchElevatedPlaneTest;
  
    model GroundWrenchZeroLoadTest
      "No COP is valid under zero, subthreshold, or negative resultant normal load"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor w[3](each nZones=1,each fzEps=1e-6);
      parameter Real forces[3]={0,1e-9,-10};
      output Real observedValid[3];
      output Real observedCOP[3,2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:3 loop
        w[i].rWorld=[1,2,0]; w[i].forceWorld=[2,3,forces[i]]; w[i].freeMomentWorld=[0,0,1];
        observedValid[i]=if w[i].copValid then 1 else 0;
        observedCOP[i,:]=w[i].cop;
        assert(not w[i].copValid and max(abs(w[i].cop))==0 and w[i].freeMomentAtCOP==0,
          "Undefined COP validity/sentinel failure.");
      end for;
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedValid))==0 and max(abs(observedCOP))==0,
        "No-load sentinel/validity failed at check event.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end GroundWrenchZeroLoadTest;
  
    model GroundWrenchYawSeparationTest
      "Demonstrate that asymmetric normal pressure is not itself yaw torque"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor pressureOnly(nZones=2);
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor shearCouple(nZones=2);
    
      output Real observedPressureYaw=pressureOnly.yawTotal;
      output Real observedRoll=pressureOnly.resultantMoment[1];
      output Real observedShearYaw=shearCouple.yawTotal;
      output Real observedNetShear=shearCouple.resultantForce[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      // Medial/lateral normal-force asymmetry: roll moment, zero yaw.
      pressureOnly.rWorld = {
        {0,-0.05,0},
        {0, 0.05,0}};
      pressureOnly.forceWorld = {
        {0,0,600},
        {0,0,400}};
      pressureOnly.freeMomentWorld = fill(0,2,3);
    
      // Equal/opposite tangential forces at separated x positions:
      // zero net Fy, nonzero yaw moment.
      shearCouple.rWorld = {
        { 0.10,0,0},
        {-0.10,0,0}};
      shearCouple.forceWorld = {
        {0, 50,500},
        {0,-50,500}};
      shearCouple.freeMomentWorld = fill(0,2,3);
    
    initial equation
      assert(abs(pressureOnly.yawTotal) < 1e-10,
        "Normal-pressure asymmetry must not create yaw in this planar test.");
      assert(abs(pressureOnly.resultantMoment[1] + 10) < 1e-10,
        "Expected roll moment from medial/lateral pressure asymmetry.");
    
      assert(abs(shearCouple.resultantForce[2]) < 1e-10,
        "Tangential shear couple should have zero net Fy.");
      assert(abs(shearCouple.yawTotal - 10) < 1e-10,
        "Expected 10 N.m yaw moment from shear couple.");
    
    
    algorithm
      when time>=verificationTime then
        assert(abs(pressureOnly.yawTotal) < 1e-10,
        "Normal-pressure asymmetry must not create yaw in this planar test.");
        assert(abs(pressureOnly.resultantMoment[1] + 10) < 1e-10,
        "Expected roll moment from medial/lateral pressure asymmetry.");
        assert(abs(shearCouple.resultantForce[2]) < 1e-10,
        "Tangential shear couple should have zero net Fy.");
        assert(abs(shearCouple.yawTotal - 10) < 1e-10,
        "Expected 10 N.m yaw moment from shear couple.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01));
    end GroundWrenchYawSeparationTest;
  
    model TorsionalCapacityTest
      "Analytic test of the project-derived torsional capacity function"
      import SI = Modelica.Units.SI;
    
      parameter Integer n=4;
      parameter SI.Position r[n,3] = {
        { 0.10, 0.05,0},
        { 0.10,-0.05,0},
        {-0.10, 0.05,0},
        {-0.10,-0.05,0}};
      parameter SI.Force fz[n] = {100,100,100,100};
      parameter Real muT=0.2;
      parameter SI.Length expectedRadius=sqrt(0.10^2 + 0.05^2);
      parameter SI.Torque expectedCapacity=muT*400*expectedRadius;
    
      SI.Torque cap;
      SI.Length rEff;
      SI.Position cop[2];
    
      output Real observedCapacity=cap;
      output Real observedRadius=rEff;
      output Real observedX=cop[1];
      output Real observedY=cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (cap, rEff, cop) = ModelicaHumanBodyPArts.Contact.torsionalCapacity(n, r, fz, muT);
    
      assert(abs(cop[1]) < 1e-12 and abs(cop[2]) < 1e-12,
        "Symmetric load pattern must have zero normal-force COP.");
      assert(abs(rEff - expectedRadius) < 1e-10,
        "Effective radius does not match analytic symmetric result.");
      assert(abs(cap - expectedCapacity) < 1e-9,
        "Torsional capacity does not match analytic result.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(cop[1]) < 1e-12 and abs(cop[2]) < 1e-12,
        "Symmetric load pattern must have zero normal-force COP.");
        assert(abs(rEff - expectedRadius) < 1e-10,
        "Effective radius does not match analytic symmetric result.");
        assert(abs(cap - expectedCapacity) < 1e-9,
        "Torsional capacity does not match analytic result.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end TorsionalCapacityTest;
  
    model LegacyTorsionalEdgeCasesTest
      "LEGACY diagnostic function: negligible-load COP sentinel and normal-load clipping"
      Real capacity[4],radius[4],cop[4,2];
      output Real observedCapacity[4]=capacity;
      output Real observedRadius[4]=radius;
      output Real observedCOP[4,2]=cop;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (capacity[1],radius[1],cop[1,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        1,[2,3,0],{0},0.2,1e-9);
      (capacity[2],radius[2],cop[2,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        1,[2,3,0],{1e-12},0.2,1e-9);
      (capacity[3],radius[3],cop[3,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        2,[100,100,0;2,3,0],{-100,100},0.2,1e-9);
      (capacity[4],radius[4],cop[4,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        1,[2,3,0],{1e-9},0.2,1e-9);
      assert(max(abs(capacity))<1e-12 and max(abs(radius))<1e-12,
        "Zero-radius legacy capacities must vanish.");
      assert(max(abs(cop[1,:]))<1e-15 and max(abs(cop[2,:]))<1e-15 and max(abs(cop[4,:]))<1e-15,
        "Undefined legacy COP must be the zero storage sentinel.");
      assert(max(abs(cop[3,:]-{2,3}))<1e-12,"Negative-load clipping must not bias COP.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(capacity))<1e-12 and max(abs(radius))<1e-12,
        "Zero-radius legacy capacities must vanish.");
        assert(max(abs(cop[1,:]))<1e-15 and max(abs(cop[2,:]))<1e-15 and max(abs(cop[4,:]))<1e-15,
        "Undefined legacy COP must be the zero storage sentinel.");
        assert(max(abs(cop[3,:]-{2,3}))<1e-12,"Negative-load clipping must not bias COP.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end LegacyTorsionalEdgeCasesTest;
  
    model ResidualSpinBudgetTest
      Modelica.Units.SI.Torque cap;
      Modelica.Units.SI.Torque capZone[4];
      Modelica.Units.SI.Torque freeCap;
      Modelica.Units.SI.Torque freeZone[4];
      output Real observedSaturatedCapacity=cap;
      output Real observedFreeCapacity=freeCap;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (cap,capZone)=ModelicaHumanBodyPArts.Contact.residualSpinCapacity(
        4,fill(100,4),[60,0;60,0;60,0;60,0],0.6,fill(0.01,4),1);
      (freeCap,freeZone)=ModelicaHumanBodyPArts.Contact.residualSpinCapacity(
        4,fill(100,4),zeros(4,2),0.6,fill(0.01,4),1);
      assert(abs(cap)<1e-12, "Saturated local shear cannot retain independent spin capacity.");
      assert(abs(freeCap-1.6)<1e-12, "Uniform-disk no-shear capacity incorrect.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(cap)<1e-12, "Saturated local shear cannot retain independent spin capacity.");
        assert(abs(freeCap-1.6)<1e-12, "Uniform-disk no-shear capacity incorrect.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end ResidualSpinBudgetTest;
  
    model PlantarContactSpinTest
      "Driven synthetic rigid-foot spin on elevated plane; analytical wrench/spin oracle"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      parameter Real omega=0.1;
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,0.379},animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute spin(n={0,0,1},useAxisFlange=true);
      Modelica.Mechanics.Rotational.Sources.Position drive(exact=true,useSupport=false);
      Modelica.Blocks.Sources.RealExpression angle(y=omega*time);
      ModelicaHumanBodyPArts.Segments.Foot foot(props=footProps,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,animation=false);
      ModelicaHumanBodyPArts.Contact.PlantarContact contact(groundHeight=0.3,
        kNormal=100000,cNormal=0,mu=0.6,vSlip=0.01,
        torsionalFrictionFactor=0.8,patchRadius=fill(0.005,6),omegaTorsionSlip=0.05);
      output Real observedGRF[3]=contact.groundReactionForce;
      output Real observedCOP[2]=contact.cop;
      output Real observedCapacity=contact.torsionalCapacity;
      output Real observedFreeYaw=contact.yawFromFreeMoment;
      output Real observedShearYaw=contact.yawFromShear;
      output Real observedTotalYaw=contact.yawTotal;
      output Real observedSpin=spin.w;
      output Real observedFrictionUtilization=contact.torsionalUtilization;
      parameter Modelica.Units.SI.Time verificationTime=0.090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(anchor.frame_b,spin.frame_a);
      connect(angle.y,drive.phi_ref);
      connect(drive.flange,spin.axis);
      connect(spin.frame_b,foot.frame_ankle);
      connect(foot.frame_ankle,contact.frame_torsion);
      for i in 1:6 loop
        connect(foot.frame_plantar[i],contact.plantarFrames[i]);
      end for;
      assert(abs(observedGRF[3]-600)<1e-5 and contact.copValid,"Six-zone normal force/valid COP failed.");
      assert(observedCapacity>0 and observedFreeYaw<0,
        "Active residual spin must be nonzero and dissipative.");
      assert(abs(observedTotalYaw-observedShearYaw-observedFreeYaw)<1e-8,"Yaw channels do not close.");
      assert(observedFrictionUtilization<=1+1e-10,"Spin utilization exceeds conservative capacity.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(observedGRF[3]-600)<1e-5 and contact.copValid,"Six-zone normal force/valid COP failed.");
        assert(observedCapacity>0 and observedFreeYaw<0,
        "Active residual spin must be nonzero and dissipative.");
        assert(abs(observedTotalYaw-observedShearYaw-observedFreeYaw)<1e-8,"Yaw channels do not close.");
        assert(observedFrictionUtilization<=1+1e-10,"Spin utilization exceeds conservative capacity.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.1,Tolerance=1e-9));
    end PlantarContactSpinTest;
  
    model JointLimitMonitorTest
      "Five reached assertion stages: outside/lower/interior/upper/outside, plus ties"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(
        n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter Real bankQ[7,3]={{0,0,0},{-1,0,0},{0,1,0},{0,0,1.1},
        {-0.5,0.9,0},{0.9,-0.9,0},{0,-1.2,0}};
      parameter Integer nearest[7]={1,1,2,3,2,1,2};
      parameter Integer ties[7]={3,1,1,1,1,2,1};
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor bank[7](each n=3,each mobility=rom);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor sweep(n=3,mobility=rom);
      output Integer checksPassed(start=0,fixed=true)
        "Completed timed assertion stages, not assertion count";
      output Real observedSweepUtilization=sweep.utilization[1];
      output Real observedSweepMargin=sweep.distanceToLimit[1];
      output Real observedTieCount=bank[6].nearestMarginCount;
      output Real observedTieIndex=bank[6].limitingDOF;
    equation
      sweep.q={-1.25+2.5*time,0,0};
      for i in 1:7 loop
        bank[i].q=bankQ[i,:];
        assert(bank[i].limitingDOF==nearest[i],"Nearest DOF identity/tie-breaking failure.");
        assert(bank[i].nearestMarginCount==ties[i],"Nearest-margin tie reporting failure.");
      end for;
      assert(not bank[1].atLimit[1] and not bank[1].violated[1],"Interior misclassified.");
      assert(bank[2].atLimit[1] and not bank[2].violated[1],"Lower boundary misclassified.");
      assert(bank[3].atLimit[2] and not bank[3].violated[2],"Upper boundary misclassified.");
      assert(bank[4].violated[3] and bank[7].violated[2],"Outside cases missed.");
      assert(bank[6].nearestMarginTie[1] and bank[6].nearestMarginTie[2]
        and not bank[6].nearestMarginTie[3],"Tie mask is incorrect.");
    algorithm
      when {time>=0.05,time>=0.10,time>=0.50,time>=0.90,time>=0.99} then
        if time<0.075 then
          assert(sweep.violated[1] and sweep.marginLower[1]<0,"Lower outside sweep case missed.");
        elseif time<0.30 then
          assert(abs(sweep.marginLower[1])<1e-8 and sweep.atLimit[1]
            and not sweep.violated[1],"Lower boundary event missed.");
        elseif time<0.70 then
          assert(abs(sweep.utilization[1])<1e-8 and not sweep.atLimit[1],"Interior event missed.");
        elseif time<0.95 then
          assert(abs(sweep.marginUpper[1])<1e-8 and sweep.atLimit[1]
            and not sweep.violated[1],"Upper boundary event missed.");
        else
          assert(sweep.violated[1] and sweep.marginUpper[1]<0,"Upper outside event missed.");
        end if;
        checksPassed:=pre(checksPassed)+1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1.0,Tolerance=1e-9,Interval=0.001));
    end JointLimitMonitorTest;
  
    model ScalingSmokeTest
      "Static assertions for v0.2 scaling resolution"
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile p(
        height=1.75,
        mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,
        footWidth=0.095,
        ankleFromHeel=0.07,
        ankleHeight=0.08,
        shankLength=0.43,
        thighLength=0.44,
        pelvisLength=0.18,
        hipCenterDistance=0.20);
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties foot =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shank =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thigh =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties pelvis =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Pelvis);
    
      output Real observedFootMass=foot.mass;
      output Real observedShankMass=shank.mass;
      output Real observedThighMass=thigh.mass;
      output Real observedPelvisMass=pelvis.mass;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial algorithm
      assert(abs(foot.mass/p.mass - 0.0137) < 1e-12, "Male foot mass fraction mismatch.");
      assert(abs(shank.mass/p.mass - 0.0433) < 1e-12, "Male shank mass fraction mismatch.");
      assert(abs(thigh.mass/p.mass - 0.1416) < 1e-12, "Male thigh mass fraction mismatch.");
      assert(abs(pelvis.mass/p.mass - 0.1117) < 1e-12, "Male pelvis mass fraction mismatch.");
    
      assert(foot.ISagittal > 0 and foot.ITransverse > 0 and foot.ILongitudinal > 0,
        "Foot inertias must be positive.");
      assert(shank.ISagittal > 0 and thigh.ISagittal > 0 and pelvis.ISagittal > 0,
        "All resolved segment inertias must be positive.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(foot.mass/p.mass - 0.0137) < 1e-12, "Male foot mass fraction mismatch.");
        assert(abs(shank.mass/p.mass - 0.0433) < 1e-12, "Male shank mass fraction mismatch.");
        assert(abs(thigh.mass/p.mass - 0.1416) < 1e-12, "Male thigh mass fraction mismatch.");
        assert(abs(pelvis.mass/p.mass - 0.1117) < 1e-12, "Male pelvis mass fraction mismatch.");
        assert(foot.ISagittal > 0 and foot.ITransverse > 0 and foot.ILongitudinal > 0,
        "Foot inertias must be positive.");
        assert(shank.ISagittal > 0 and thigh.ISagittal > 0 and pelvis.ISagittal > 0,
        "All resolved segment inertias must be positive.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end ScalingSmokeTest;
  
    model FootCOMOffsetTest
      "COM coordinate bookkeeping only; 30 mm override is a synthetic test, not anatomical data"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      ModelicaHumanBodyPArts.Segments.Foot baseline(props=footProps,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,animation=false);
      ModelicaHumanBodyPArts.Segments.Foot offset(props=footProps,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,comAboveSole=0.03,
        comOffsetSourceId="SYNTHETIC_VERIFICATION_ONLY",animation=false);
      output Real observedBaseline[3]=baseline.comPositionLocal;
      output Real observedOffset[3]=offset.comPositionLocal;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(world.frame_b,baseline.frame_ankle);
      connect(world.frame_b,offset.frame_ankle);
      assert(abs(observedBaseline[3]+0.08)<1e-12,"Legacy sole-plane default changed silently.");
      assert(abs(observedOffset[3]+0.05)<1e-12,"Explicit COM offset mapping failed.");
      assert(abs(observedOffset[1]-(0.4415*0.26-0.07))<1e-12,"COM longitudinal origin changed.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(observedBaseline[3]+0.08)<1e-12,"Legacy sole-plane default changed silently.");
        assert(abs(observedOffset[3]+0.05)<1e-12,"Explicit COM offset mapping failed.");
        assert(abs(observedOffset[1]-(0.4415*0.26-0.07))<1e-12,"COM longitudinal origin changed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end FootCOMOffsetTest;
  
    model AffineMassPropertiesTest
      Modelica.Units.SI.Position c[3];
      Modelica.Units.SI.Inertia I[3,3];
      parameter Modelica.Units.SI.Mass m=2;
      parameter Modelica.Units.SI.Length a=0.2,b=0.3,d=0.4;
      parameter Modelica.Units.SI.Inertia I0[3,3]=diagonal(
        {m*(b*b+d*d)/12,m*(a*a+d*d)/12,m*(a*a+b*b)/12});
      parameter Modelica.Units.SI.Inertia target[3,3]=diagonal(
        {3*((0.3*0.5)^2+(0.4*1.5)^2)/12,
         3*((0.2*2)^2+(0.4*1.5)^2)/12,
         3*((0.2*2)^2+(0.3*0.5)^2)/12});
      output Real observedCOM[3]=c;
      output Real observedInertia[3,3]=I;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (c,I)=ModelicaHumanBodyPArts.Utilities.affineMassProperties(m,{0,0,0},I0,
        diagonal({2,0.5,1.5}),{0.1,-0.2,0.3},3);
      assert(max(abs(I-target))<1e-12 and max(abs(c-{0.1,-0.2,0.3}))<1e-12,
        "Affine box mass-property test failed.");
      assert(not ModelicaHumanBodyPArts.Utilities.physicalInertia(diagonal({1,1,3})),
        "Positive but nonphysical inertia was accepted.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(I-target))<1e-12 and max(abs(c-{0.1,-0.2,0.3}))<1e-12,
        "Affine box mass-property test failed.");
        assert(not ModelicaHumanBodyPArts.Utilities.physicalInertia(diagonal({1,1,3})),
        "Positive but nonphysical inertia was accepted.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end AffineMassPropertiesTest;
  
    model PhysicalPendulumTest
      "Uniform cylinder pendulum: synthetic mechanical verification, not human validation"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1},g=9.81);
      parameter SI.Mass m=3;
      parameter SI.Length L=0.43;
      parameter SI.Length radius=0.03;
      parameter SI.Angle q0=0.3;
      parameter SI.Inertia Ic=m*(L^2+3*radius^2)/12;
      parameter SI.Inertia J=Ic+m*(L/2)^2;
      parameter SI.Energy E0=m*9.81*(L/2)*(1-cos(q0));
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties props(
        mass=m,length=L,comFraction=0.5,comDistance=L/2,
        ISagittal=Ic,ITransverse=Ic,ILongitudinal=m*radius^2/2,
        sourceId="Synthetic uniform cylinder; analytic reference only");
      Modelica.Mechanics.MultiBody.Joints.Revolute joint(
        n={0,1,0},phi(start=q0,fixed=true),w(start=0,fixed=true));
      ModelicaHumanBodyPArts.Segments.Shank rod(props=props,animation=false);
      output SI.Angle q=joint.phi;
      output SI.Energy energy=0.5*J*joint.w^2+m*9.81*(L/2)*(1-cos(joint.phi));
      output Real relativeEnergyError=(energy-E0)/E0;
      parameter Modelica.Units.SI.Time verificationTime=4.8695229516542584;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(world.frame_b,joint.frame_a);
      connect(joint.frame_b,rod.frame_proximal);
      assert(abs(relativeEnergyError)<1e-5,"Pendulum energy check failed.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(relativeEnergyError)<1e-5,"Pendulum energy check failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=5.41058105739362,Tolerance=1e-8));
    end PhysicalPendulumTest;
  
    model ROMSourceSideTest
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile L(n=1)=
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean(true);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile R(n=1)=
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean(false);
      output Real observedLeftMin=Modelica.Units.Conversions.to_deg(L.qMin[1]);
      output Real observedRightMin=Modelica.Units.Conversions.to_deg(R.qMin[1]);
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial equation
      assert(abs(Modelica.Units.Conversions.to_deg(L.qMin[1])+1.7)<1e-10,
        "Left knee source mean incorrect.");
      assert(abs(Modelica.Units.Conversions.to_deg(R.qMin[1])+1.6)<1e-10,
        "Right knee source mean incorrect.");
      assert(L.romNature==ModelicaHumanBodyPArts.Types.ROMNature.Passive and L.hasUncertainty,
        "Passive population-SD metadata missing.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(Modelica.Units.Conversions.to_deg(L.qMin[1])+1.7)<1e-10,
        "Left knee source mean incorrect.");
        assert(abs(Modelica.Units.Conversions.to_deg(R.qMin[1])+1.6)<1e-10,
        "Right knee source mean incorrect.");
        assert(L.romNature==ModelicaHumanBodyPArts.Types.ROMNature.Passive and L.hasUncertainty,
        "Passive population-SD metadata missing.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end ROMSourceSideTest;
  
    model PublishedSourceTablesTest
      "Table-transcription regression; not biological validation"
      parameter ModelicaHumanBodyPArts.Records.BSIPCoefficients maleShank =
        ModelicaHumanBodyPArts.Data.DeLeva1996.male(ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.BSIPCoefficients femaleShank =
        ModelicaHumanBodyPArts.Data.DeLeva1996.female(ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.PublishedBSIPRow riderShank =
        ModelicaHumanBodyPArts.Data.Bova2020LowerLimb.deLevaRiderRow(ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.PublishedBSIPRow riderFoot =
        ModelicaHumanBodyPArts.Data.Bova2020LowerLimb.dumasRiderRow(ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      output Real observedMaleShankCOM=maleShank.comFraction;
      output Real observedFemaleShankCOM=femaleShank.comFraction;
      output Real observedBovaShankBeta=riderShank.beta[3];
      output Real observedFootRef=riderFoot.lengthPerStature;
      output Real observedCrossRadius=riderFoot.crossEta[3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial equation
      assert(abs(maleShank.comFraction-0.4395)<1e-12,"HAS male shank COM transcription");
      assert(abs(femaleShank.comFraction-0.4352)<1e-12,"HAS female shank COM transcription");
      assert(abs(riderShank.beta[3]+0.4459)<1e-12,"Keep Bova normalization distinct");
      assert(abs(riderFoot.lengthPerStature-0.1034)<1e-12,"Do not use full heel-to-toe scaling");
      assert(abs(riderFoot.crossEta[3]-0.13)<1e-12,"Table A6 xz cross radius retained");
      assert(not riderFoot.tensorConversionApproved,"Unverified tensor adapter cannot be enabled");
    
    algorithm
      when time>=verificationTime then
        assert(abs(maleShank.comFraction-0.4395)<1e-12,"HAS male shank COM transcription");
        assert(abs(femaleShank.comFraction-0.4352)<1e-12,"HAS female shank COM transcription");
        assert(abs(riderShank.beta[3]+0.4459)<1e-12,"Keep Bova normalization distinct");
        assert(abs(riderFoot.lengthPerStature-0.1034)<1e-12,"Do not use full heel-to-toe scaling");
        assert(abs(riderFoot.crossEta[3]-0.13)<1e-12,"Table A6 xz cross radius retained");
        assert(not riderFoot.tensorConversionApproved,"Unverified tensor adapter cannot be enabled");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end PublishedSourceTablesTest;
  
    model S45ReplayTest
      "Imported scalar replay fixture, with an explicit timed completion check"
      Modelica.Units.SI.Angle qa,qk;
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.005;
    equation
      (qa,qk)=ModelicaHumanBodyPArts.CanonicalReplay.s45Kinematics(0.4);
    algorithm
      when time>=verificationTime then
        assert(abs(qa*180/Modelica.Constants.pi-12)<1e-9,"S45 ankle mismatch");
        assert(abs(qk*180/Modelica.Constants.pi-3.4542794188062427)<1e-9,"S45 knee mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end S45ReplayTest;
  
    model S46ReplayTest
      "Imported scalar replay fixture, with an explicit timed completion check"
      Modelica.Units.SI.Force F;
      Modelica.Units.SI.Angle q;
      Modelica.Units.SI.Position cu,cs;
      Real hu,hs;
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.005;
    equation
      (F,q,cu,cs,hu,hs)=ModelicaHumanBodyPArts.CanonicalReplay.s46Diagnostics(x=0.4,a=0,beta=0.09375);
    algorithm
      when time>=verificationTime then
        assert(abs(F-68.9765625)<1e-9,"S46 force mismatch");
        assert(abs(cu-0.15)<1e-12 and abs(hu)<1e-12,"S46 heel threshold mismatch");
        assert(abs(q*180/Modelica.Constants.pi-14.477512185929925)<1e-9,"S46 ankle mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end S46ReplayTest;
  

    model AuditedPlantarKnownLoadTest
      "Known-answer six-zone regional-load and static energy audit"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter Real k(unit="N/m")=100000;
      parameter Modelica.Units.SI.Length delta=0.0001635;
      Modelica.Mechanics.MultiBody.Parts.Fixed base(animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z[6](each r={0,0,-delta},each animation=false);
      ModelicaHumanBodyPArts.Contact.AuditedPlantarContact contact(kNormal=k,cNormal=0,mu=0,vSlip=0.01);
      output Modelica.Units.SI.Force totalNormal=sum(contact.zoneNormalForce);
      output Integer checksPassed(start=0,fixed=true);
    equation
      for i in 1:6 loop connect(base.frame_b,z[i].frame_a); connect(z[i].frame_b,contact.plantarFrames[i]); end for;
      connect(base.frame_b,contact.frame_torsion);
    algorithm
      when time>=0.009 then
        assert(abs(totalNormal-98.1)<1e-6,"Known total normal load failed");
        assert(abs(contact.heelLoad-32.7)<1e-6 and abs(contact.midfootLoad-32.7)<1e-6 and abs(contact.forefootLoad-32.7)<1e-6,"Regional load split failed");
        assert(contact.broadSupport and abs(contact.heelShare-1/3)<1e-10,"Regional support observer failed");
        assert(abs(contact.lossPower)<1e-10 and abs(contact.powerToBody)<1e-10 and abs(contact.identityResidual)<1e-8,"Static contact energy audit failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end AuditedPlantarKnownLoadTest;

    model AuditedPlantarHeelUnloadTest
      "Observer distinguishes supported foot with unloaded heel from broad support"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter Real k(unit="N/m")=100000;
      Modelica.Mechanics.MultiBody.Parts.Fixed base(animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z1(r={0,0,0.001},animation=false),z2(r={0,0,0.001},animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z3(r={0,0,-0.0002},animation=false),z4(r={0,0,-0.0002},animation=false),z5(r={0,0,-0.0002},animation=false),z6(r={0,0,-0.0002},animation=false);
      ModelicaHumanBodyPArts.Contact.AuditedPlantarContact contact(kNormal=k,cNormal=0,mu=0,vSlip=0.01);
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(base.frame_b,z1.frame_a);connect(z1.frame_b,contact.plantarFrames[1]);
      connect(base.frame_b,z2.frame_a);connect(z2.frame_b,contact.plantarFrames[2]);
      connect(base.frame_b,z3.frame_a);connect(z3.frame_b,contact.plantarFrames[3]);
      connect(base.frame_b,z4.frame_a);connect(z4.frame_b,contact.plantarFrames[4]);
      connect(base.frame_b,z5.frame_a);connect(z5.frame_b,contact.plantarFrames[5]);
      connect(base.frame_b,z6.frame_a);connect(z6.frame_b,contact.plantarFrames[6]);
      connect(base.frame_b,contact.frame_torsion);
    algorithm
      when time>=0.009 then
        assert(contact.supportValid and contact.heelLoad<1e-9,"Heel unload fixture did not unload heel");
        assert(not contact.broadSupport,"Broad-support observer failed to reject heel-unloaded support");
        assert(abs(contact.midfootLoad-40)<1e-6 and abs(contact.forefootLoad-40)<1e-6,"Supported regional loads incorrect");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end AuditedPlantarHeelUnloadTest;


    model LoadedSupportVariableImpedanceEnergyTest
      "Aggregate variable-impedance energy ledger on the gravity-loaded articulated body"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1},g=9.81,gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_ENERGY_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.1,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_ENERGY_PELVIS");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.5,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1}},R_principal=identity(3),segmentFrameId="SYNTHETIC_ENERGY_TRUNK");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-0.5,-0.7,-0.7},qMax={2.2,0.7,0.7},sourceId="SYNTHETIC_ENERGY_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-0.15},qMax={2.8},sourceId="SYNTHETIC_ENERGY_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-0.8,-0.6},qMax={0.8,0.6},sourceId="SYNTHETIC_ENERGY_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin=fill(-0.5,3),qMax=fill(0.5,3),sourceId="SYNTHETIC_ENERGY_ROM");
      parameter SI.Angle initialQ[15]={0,0,0,0,0,-0.115275665089173,0.25,0,0,0.5,0.25,0.115275665089173,0,0,0};
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,0.08},animation=false);
      ModelicaHumanBodyPArts.Transmission.SmoothImpedanceSchedule schedule(preparationEnd=0.10,releaseEnd=0.40,initialScale=1,preparationScale=1,releaseScale=0.6);
      ModelicaHumanBodyPArts.SupportInitiation.LoadedSupportBody body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.1,shoulderWidth=0.4,footCOMAboveSole=0.035,footCOMOffsetSourceId="SYNTHETIC_ENERGY_OFFSET",hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,leftHipStart=initialQ[1:3],leftKneeStart=initialQ[4],leftAnkleStart=initialQ[5:6],rightHipStart=initialQ[7:9],rightKneeStart=initialQ[10],rightAnkleStart=initialQ[11:12],lumbarStart=initialQ[13:15],fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed=fill(true,3),lumbarWFixed=fill(true,3),useVariableImpedance=true,animation=false);
      output SI.Energy dampingLoss(start=0,fixed=true);
      output SI.Energy modulationWorkToMechanical(start=0,fixed=true);
      output SI.Energy energyResidual=body.mechanicalEnergy-energy0+dampingLoss+modulationWorkToMechanical;
      output Integer checksPassed(start=0,fixed=true);
    protected
      parameter SI.Energy energy0(fixed=false);
    initial equation
      energy0=body.mechanicalEnergy;
    equation
      connect(support.frame_b,body.leftFootReference);
      body.ankleActuation=0; body.hipYawActuation=0;
      body.leftHipControl=cat(1,fill(schedule.scale,3),fill(schedule.scale,3),fill(schedule.scaleRate,3));
      body.rightHipControl=body.leftHipControl;
      body.lumbarControl=body.leftHipControl;
      der(dampingLoss)=body.dissipationPower;
      der(modulationWorkToMechanical)=body.totalStiffnessModulationPower;
    algorithm
      when time>=0.49 then
        assert(abs(energyResidual)<1e-4,"Aggregate variable-impedance energy ledger failed");
        assert(abs(body.actualStiffness[1]-0.6*body.stiffness[1])<1e-8 and abs(body.actualDamping[1]-0.6*body.damping[1])<1e-8,"Actual coefficient reporting failed");
        assert(body.dissipationPower>=-1e-9,"Aggregate dissipation became negative");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.001));
    end LoadedSupportVariableImpedanceEnergyTest;

  end Tests;

