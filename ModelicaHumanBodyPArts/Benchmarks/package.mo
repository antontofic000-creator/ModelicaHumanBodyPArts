within ModelicaHumanBodyPArts;
  package Benchmarks "Synthetic assembled-mechanics verification; not measured human movement"
    extends Modelica.Icons.ExamplesPackage;
  
    partial model PartialFixture "Declared synthetic dimensions and fixed-pelvis boundary"
      parameter Real scaleFactor(min=0.1)=1;
      parameter Modelica.Units.SI.Mass bodyMass=75;
      parameter Modelica.Units.SI.Position rootHeight=1.10*scaleFactor;
      inner Modelica.Mechanics.MultiBody.World world(g=9.81,n={0,0,-1},enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75*scaleFactor,mass=bodyMass,sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=.26*scaleFactor,footWidth=.095*scaleFactor,
        ankleFromHeel=.07*scaleFactor,ankleHeight=.08*scaleFactor,
        shankLength=.43*scaleFactor,thighLength=.44*scaleFactor,
        pelvisLength=.18*scaleFactor,hipCenterDistance=.20*scaleFactor,
        geometrySourceId="SYNTHETIC_ASSEMBLED_BENCHMARK_NOT_HUMAN_DATA");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,
        qMin={-4,-2,-4},qMax={4,2,4},sourceId="SYNTHETIC_DIAGNOSTIC_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,
        qMin={-4},qMax={4},sourceId="SYNTHETIC_DIAGNOSTIC_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,
        qMin={-4,-2},qMax={4,2},sourceId="SYNTHETIC_DIAGNOSTIC_ONLY");
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,rootHeight},animation=false);
    end PartialFixture;
  
    model FreeSwing "Unactuated bilateral articulated chain; a planar invariant benchmark"
      extends PartialFixture;
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        leftHipStart={.4,0,0},rightHipStart={.4,0,0},
        leftKneeStart=.8,rightKneeStart=.8,leftAnkleStart={.4,0},rightAnkleStart={.4,0},
        animation=false);
      output Modelica.Units.SI.Angle qL[6],qR[6];
      output Modelica.Units.SI.AngularVelocity wL[6],wR[6];
      output Modelica.Units.SI.AngularAcceleration aL[6],aR[6];
      output Modelica.Units.SI.Force supportForce[3];
      output Modelica.Units.SI.Mass representedMass;
      output Integer completed(start=0,fixed=true);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      qL=body.leftQ; qR=body.rightQ;
      wL=der(qL);wR=der(qR);aL=der(wL);aR=der(wR);
      supportForce=body.frame_pelvisProximal.f;
      representedMass=body.representedMass;
    algorithm
      when time>=1.49 then
        assert(max(abs(qL-qR))<1e-7,"Bilateral symmetry lost in free-swing fixture");
        completed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.0005));
    end FreeSwing;
  
    model GroundedRelease "Fixed-pelvis articulated release into compliant ground; not human stance"
      extends PartialFixture;
      parameter Real stiffness(unit="N/m")=100000;
      parameter Real damping(unit="N.s/m")=500;
      parameter Real friction=0.7;
      parameter Modelica.Units.SI.Velocity slipSpeed=0.01;
      ModelicaHumanBodyPArts.Assemblies.LowerBodyGroundedAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        leftHipStart={.4,0,0},rightHipStart={.4,0,0},leftKneeStart=.8,rightKneeStart=.8,
        leftAnkleStart={.4,0},rightAnkleStart={.4,0},groundHeight=0,
        kNormal=stiffness,cNormal=damping,mu=friction,vSlip=slipSpeed,
        torsionalFrictionFactor=0,patchRadius=fill(.005,6));
      output Modelica.Units.SI.Angle qL[6],qR[6];
      output Modelica.Units.SI.AngularVelocity wL[6],wR[6];
      output Modelica.Units.SI.AngularAcceleration aL[6],aR[6];
      output Modelica.Units.SI.Force supportForce[3],groundForce[3];
      output Modelica.Units.SI.Mass representedMass;
      output Modelica.Units.SI.Power contactPower;
      output Modelica.Units.SI.Energy contactWork(start=0,fixed=true);
      output Modelica.Units.SI.Length maxPenetration;
      output Integer completed(start=0,fixed=true);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      qL=body.leftQ;qR=body.rightQ;wL=der(qL);wR=der(qR);aL=der(wL);aR=der(wR);
      representedMass=body.representedMass;
      supportForce=body.frame_pelvisProximal.f;groundForce=body.leftGRF+body.rightGRF;
      contactPower=sum(body.leftZoneForce[i,:]*der(body.leftZonePosition[i,:])
        +body.rightZoneForce[i,:]*der(body.rightZonePosition[i,:]) for i in 1:6);
      der(contactWork)=contactPower;
      maxPenetration=max(0,max(-body.leftZonePosition[:,3]));
    algorithm
      when time>=.499 then
        assert(max(abs(qL-qR))<1e-6,"Bilateral symmetry lost in grounded fixture");
        completed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=.5,Tolerance=1e-8,Interval=.0001));
    end GroundedRelease;
  
  end Benchmarks;

