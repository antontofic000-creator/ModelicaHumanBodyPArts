within ModelicaHumanBodyPArts;
  package BuildFixtures
    "Fully specified assembly translation/build roots; no biomechanical validity claim"
    extends Modelica.Icons.ExamplesPackage;
  
    model LowerBodyAssemblyBuild
      "Build fixture only: fixed pelvis, specified joint initialization, synthetic dimensions"
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
    
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,1.1299999999999999},animation=false);
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,animation=false);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyAssemblyBuild;
  
    model LowerBodyGroundedBuild
      "Build fixture only: fixed pelvis, specified joint initialization, synthetic dimensions"
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
    
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,1.1299999999999999},animation=false);
      ModelicaHumanBodyPArts.Assemblies.LowerBodyGroundedAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,groundHeight=0,
        torsionalFrictionFactor=0,patchRadius=fill(0.005,6),kNormal=10000,cNormal=100);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyGroundedBuild;
  
    model LowerBodyGroundedElevatedSpinBuild
      "Build fixture only: fixed pelvis, specified joint initialization, synthetic dimensions"
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
    
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,1.48},animation=false);
      ModelicaHumanBodyPArts.Assemblies.LowerBodyGroundedAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,groundHeight=0.35,
        torsionalFrictionFactor=0.8,patchRadius=fill(0.005,6),kNormal=10000,cNormal=100);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyGroundedElevatedSpinBuild;
  
  end BuildFixtures;

