within ModelicaHumanBodyPArts;
  package Examples
    extends Modelica.Icons.ExamplesPackage;
  
    model LowerBodyFreeChainDemo
      "Numerical smoke test only; parameter values are not validation data"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,
        n={0,0,-1});
    
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
    
      // Example-only ROM values. They must not be interpreted as universal
      // anatomical constants and will be replaced by the dedicated ROM dataset.
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,
        qMin={-0.35,-0.52,-0.79},
        qMax={2.09,0.79,0.79},
        sourceId="DEMO_ONLY");
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,
        qMin={0},
        qMax={2.36},
        sourceId="DEMO_ONLY");
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,
        qMin={-0.87,-0.26},
        qMax={0.35,0.61},
        sourceId="DEMO_ONLY");
    
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedPelvis(r={0,0,1.0});
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,
        hipMobility=hipROM,
        kneeMobility=kneeROM,
        ankleMobility=ankleROM);
    
    equation
      connect(fixedPelvis.frame_b, body.frame_pelvisProximal);
    
      annotation(
        experiment(StartTime=0, StopTime=1.0, Tolerance=1e-6, Interval=0.002),
        Documentation(info="<html>
        <p>This model is intended only to smoke-test translation/assembly in a
        Modelica compiler. The ROM numbers are examples, not source-validated
        human constants.</p>
        </html>"));
    end LowerBodyFreeChainDemo;
  
    model LowerBodyRoaasMeanDemo
      "Lower-body smoke test using one source-traceable passive ROM profile"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,
        n={0,0,-1});
    
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
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3) =
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.hipMean();
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1) =
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean();
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2) =
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.ankleMean();
    
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedPelvis(r={0,0,1.0});
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,
        hipMobility=hipROM,
        kneeMobility=kneeROM,
        ankleMobility=ankleROM,
        rightHipMobility=ModelicaHumanBodyPArts.Data.RoaasAndersson1982.hipMean(false),
        rightKneeMobility=ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean(false),
        rightAnkleMobility=ModelicaHumanBodyPArts.Data.RoaasAndersson1982.ankleMean(false));
    
    equation
      connect(fixedPelvis.frame_b, body.frame_pelvisProximal);
    
      annotation(
        experiment(StartTime=0, StopTime=1.0, Tolerance=1e-6, Interval=0.002),
        Documentation(info="<html>
        <p>Only the ROM bounds are source-traceable here. The example geometry
        values remain smoke-test inputs and are not a validated anthropometric
        subject.</p>
        </html>"));
    end LowerBodyRoaasMeanDemo;
  
  end Examples;

