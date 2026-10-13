within;
package Article1ContactTutorial
  "Separate publication examples; the DOI-backed library is not modified"
  model GuidedStandingContact
    "Gravity-loaded bilateral body; vertical contact load with explicit five-DOF guide"
    import SI=Modelica.Units.SI;
    parameter SI.Length initialLift=0;
    parameter Real contactStiffness(unit="N/m")=200000;
    parameter Real contactDamping(unit="N.s/m")=500;
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
      ModelicaHumanBodyPArts.SupportInitiation.LoadedSupportBody body(profile=profile,pelvicProps=pp,thoraxProps=tp,
        lumbosacralToHipVertical=0.1,shoulderWidth=0.4,footCOMAboveSole=0.035,
        footCOMOffsetSourceId="SYNTHETIC_M2B_OFFSET",hipMobility=hipROM,kneeMobility=kneeROM,
        ankleMobility=ankleROM,lumbarMobility=lumbarROM,leftHipStart=initialQ[1:3],
        leftKneeStart=initialQ[4],leftAnkleStart=initialQ[5:6],rightHipStart=initialQ[7:9],
        rightKneeStart=initialQ[10],rightAnkleStart=initialQ[11:12],lumbarStart=initialQ[13:15],
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        lumbarFixed=fill(true,3),lumbarWFixed=fill(true,3),animation=false);

    parameter ModelicaHumanBodyPArts.Records.SegmentProperties thigh=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
    parameter ModelicaHumanBodyPArts.Records.SegmentProperties shank=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
    parameter ModelicaHumanBodyPArts.Records.SegmentProperties foot=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    parameter SI.Mass mass=pp.mass+tp.mass+2*(thigh.mass+shank.mass+foot.mass);
    Modelica.Mechanics.MultiBody.Parts.Fixed groundFrame(animation=false);
    Modelica.Mechanics.MultiBody.Joints.Prismatic guide(n={0,0,1},useAxisFlange=false,
      s(start=profile.ankleHeight-mass*9.81/(6*contactStiffness)+initialLift,fixed=true),
      v(start=0,fixed=true),animation=false);
    ModelicaHumanBodyPArts.Contact.AuditedPlantarContact contact(
      kNormal=contactStiffness,cNormal=contactDamping,mu=0.6,vSlip=0.01);
    output SI.Force normalLoad=sum(contact.zoneNormalForce);
    output SI.Force guideVerticalForce=groundFrame.frame_b.f[3];
    output SI.Force forceResidual=normalLoad-mass*9.81-mass*body.representedCOMAcceleration[3];
    output Real regionalShares[3]={contact.heelLoad,contact.midfootLoad,contact.forefootLoad}/normalLoad;
    output SI.Energy dissipated(start=0,fixed=true);
    output SI.Energy totalEnergy=body.mechanicalEnergy+contact.storedEnergy;
    output SI.Energy energyResidual=totalEnergy-initialEnergy+dissipated;
    output Integer checksPassed(start=0,fixed=true);
  protected
    parameter SI.Energy initialEnergy(fixed=false);
  initial equation
    initialEnergy=totalEnergy;
  equation
    connect(groundFrame.frame_b,guide.frame_a);
    connect(guide.frame_b,body.leftFootReference);
    connect(body.leftFootReference,contact.frame_torsion);
    for i in 1:6 loop
      connect(body.leftPlantarFrames[i],contact.plantarFrames[i]);
    end for;
    body.ankleActuation=0;
    body.hipYawActuation=0;
    der(dissipated)=body.dissipationPower+contact.lossPower;
    assert(abs(guideVerticalForce)<1e-7,"Guide bypassed the vertical contact load path");
    assert(abs(forceResidual)<1e-3,"Whole represented-body vertical force balance failed");
    assert(abs(energyResidual)<1e-6,"Body plus contact energy balance failed");
    assert(abs(contact.identityResidual)<1e-6,"Contact power identity failed");
    assert(min(contact.zoneNormalForce)>=0,"Tensile normal contact force");
  algorithm
    when time>=0.74 then
      assert(abs(body.representedMass-mass)<1e-10,"Represented mass mismatch");
      assert(abs(normalLoad-mass*9.81)<0.01*mass*9.81,"Final support has not settled within one percent of weight");
      assert(contact.broadSupport and min(regionalShares)>0.05,"A regional pair lost support");
      assert(max(abs(regionalShares-fill(1.0/3,3)))<1e-8,"Flat equal-stiffness regional split failed");
      checksPassed:=1;
    end when;
    annotation(experiment(StopTime=0.75,Interval=0.001,Tolerance=1e-8),Documentation(info="<html><p>This is a guided mechanical verification, not free standing or human balance validation. The ideal prismatic guide constrains horizontal translation and all rotations of the support foot, carries no vertical force and does no work. Vertical support is generated by the six compliant contact elements. Equal regional shares are consequences of flat geometry and equal stiffness, not anatomical predictions. InitialLift perturbs the vertical equilibrium to test the coupled force and energy identities during motion.</p></html>"));
  end GuidedStandingContact;
  model GuidedStandingPerturbation
    extends GuidedStandingContact(initialLift=0.0001);
  end GuidedStandingPerturbation;
  model SupportBypassNegativeControl
    "Passing test means that an intentionally bypassed contact path is detected"
    extends ModelicaHumanBodyPArts.SupportInitiation.M2bBaseline(enforceNecessaryContactGate=false);
    ModelicaHumanBodyPArts.Contact.AuditedPlantarContact contact(kNormal=200000,cNormal=500,mu=0.6);
    output Boolean bypassObserved=sum(contact.zoneNormalForce)<0.01*body.representedMass*9.81 and groundForce[3]>0.99*body.representedMass*9.81;
  equation
    connect(body.leftFootReference,contact.frame_torsion);
    for i in 1:6 loop
      connect(body.leftPlantarFrames[i],contact.plantarFrames[i]);
    end for;
  algorithm
    when time>=0.74 then
      assert(bypassObserved,"Negative control failed to detect support bypass");
    end when;
  end SupportBypassNegativeControl;
end Article1ContactTutorial;