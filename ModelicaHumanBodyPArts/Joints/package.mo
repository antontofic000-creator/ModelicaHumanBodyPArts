within ModelicaHumanBodyPArts;
  package Joints
    extends Modelica.Icons.Package;
  
    model Knee
      "Reduced 1-DOF knee flexion/extension"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=1);
      parameter Modelica.Units.SI.Angle phi_start=0;
      parameter Boolean phi_fixed=false
        "Fix initial knee coordinate for verification/prescribed initial configurations";
    
      parameter Modelica.Units.SI.AngularVelocity w_start=0;
      parameter Boolean w_fixed=false "Fix initial angular velocity only on request";
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
    
      output Modelica.Units.SI.Angle q;
      output Real limitUtilization;
      output Modelica.Units.SI.Angle distanceToLimit;
    
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute rev(
        n={0,1,0},
        phi(start=phi_start, fixed=phi_fixed),
        w(start=w_start, fixed=w_fixed));
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=1, mobility=mobility);
    
    equation
      connect(frame_a, rev.frame_a);
      connect(rev.frame_b, frame_b);
    
      q = rev.phi;
      monitor.q = {q};
      limitUtilization = monitor.utilization[1];
      distanceToLimit = monitor.distanceToLimit[1];
    end Knee;
  
    model AnkleComplex
      "Reduced serial 2-DOF ankle complex with library-axis mapping of ISB clinical motions"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=2);
      parameter Modelica.Units.SI.Angle q_start[2]={0,0};
      parameter Boolean q_fixed[2]=fill(false,2)
        "Fix initial joint coordinates for verification/prescribed initial configurations";
      parameter Modelica.Units.SI.AngularVelocity w_start[2]=fill(0,2);
      parameter Boolean w_fixed[2]=fill(false,2)
        "Fix initial angular velocities only when explicitly requested";
      parameter Boolean isLeft=true
        "Side-aware inversion/eversion sign";
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Shank distal";
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b "Foot proximal";
    
      output Modelica.Units.SI.Angle q[2];
      output Real limitUtilization[2];
      output Integer limitingDOF;
    
    protected
      // v0.6 library neutral axes are +x anterior, +y leftward, +z superior.
      // q1 dorsiflexion (+): rotation about -y raises the forefoot (+z).
      // q2 inversion (+): floating anterior axis; sign depends on side so the
      // medial border elevates for positive inversion.
      Modelica.Mechanics.MultiBody.Joints.Revolute dorsiPlantar(
        n={0,-1,0},
        phi(start=q_start[1], fixed=q_fixed[1]),
        w(start=w_start[1], fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute inversionEversion(
        n=if isLeft then {-1,0,0} else {1,0,0},
        phi(start=q_start[2], fixed=q_fixed[2]),
        w(start=w_start[2], fixed=w_fixed[2]));
    
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=2, mobility=mobility);
    
    equation
      connect(frame_a, dorsiPlantar.frame_a);
      connect(dorsiPlantar.frame_b, inversionEversion.frame_a);
      connect(inversionEversion.frame_b, frame_b);
    
      q = {dorsiPlantar.phi, inversionEversion.phi};
      monitor.q = q;
      limitUtilization = monitor.utilization;
      limitingDOF = monitor.limitingDOF;
    
      annotation(Documentation(info="<html>
      <p>v0.6 corrects the same axis-letter mapping error found at the hip. In the
      library's neutral axes, dorsiflexion/plantarflexion is a side-to-side y-axis
      rotation, not a rotation around the shank longitudinal z axis. The floating
      inversion/eversion axis is anterior x and is mirrored by side.</p>
      <p>The third axial rotation remains a replaceable higher-fidelity option and
      landmark-level JCS validation is still pending.</p>
      </html>"));
    end AnkleComplex;
  
    model Hip
      "Reduced serial 3-DOF hip with optional explicit passive impedance"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter Modelica.Units.SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3)
        "Fix initial joint coordinates for verification/prescribed initial configurations";
      parameter Modelica.Units.SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3)
        "Fix initial angular velocities only when explicitly requested";
      parameter Boolean isLeft=true
        "Side-aware signs for adduction and axial rotation";
      parameter Real kPassive[3](each unit="N.m/rad")={0,0,0}
        "Explicit passive joint stiffness in generalized coordinates";
      parameter Real cPassive[3](each unit="N.m.s/rad")={0,0,0}
        "Explicit passive joint damping in generalized coordinates";
      parameter Modelica.Units.SI.Angle qNeutral[3]={0,0,0};

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Pelvis hip centre";
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b "Thigh proximal";

      output Modelica.Units.SI.Angle q[3];
      output Modelica.Units.SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output Integer limitingDOF;
      output Modelica.Units.SI.Torque passiveTorque[3];
      output Modelica.Units.SI.Power passivePower;

    protected
      // Library neutral axes: +x anterior, +y leftward, +z superior.
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(
        n={0,-1,0}, useAxisFlange=true,
        phi(start=q_start[1], fixed=q_fixed[1]),
        w(start=w_start[1], fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute addAbd(
        n=if isLeft then {-1,0,0} else {1,0,0}, useAxisFlange=true,
        phi(start=q_start[2], fixed=q_fixed[2]),
        w(start=w_start[2], fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute intExt(
        n=if isLeft then {0,0,-1} else {0,0,1}, useAxisFlange=true,
        phi(start=q_start[3], fixed=q_fixed[3]),
        w(start=w_start[3], fixed=w_fixed[3]));
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveFlex(
        c=kPassive[1],d=cPassive[1],phi_rel0=-qNeutral[1]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveAdd(
        c=kPassive[2],d=cPassive[2],phi_rel0=-qNeutral[2]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveAxial(
        c=kPassive[3],d=cPassive[3],phi_rel0=-qNeutral[3]);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3, mobility=mobility);

    equation
      connect(frame_a, flexExt.frame_a);
      connect(flexExt.frame_b, addAbd.frame_a);
      connect(addAbd.frame_b, intExt.frame_a);
      connect(intExt.frame_b, frame_b);
      connect(flexExt.axis,passiveFlex.flange_a); connect(flexExt.support,passiveFlex.flange_b);
      connect(addAbd.axis,passiveAdd.flange_a); connect(addAbd.support,passiveAdd.flange_b);
      connect(intExt.axis,passiveAxial.flange_a); connect(intExt.support,passiveAxial.flange_b);

      q = {flexExt.phi, addAbd.phi, intExt.phi};
      w = {flexExt.w, addAbd.w, intExt.w};
      monitor.q = q;
      limitUtilization = monitor.utilization;
      limitingDOF = monitor.limitingDOF;
      passiveTorque=-kPassive.*(q-qNeutral)-cPassive.*w;
      passivePower=sum(passiveTorque.*w);

      annotation(Documentation(info="<html>
      <p>Clinical-axis mapping remains the corrected v0.6 convention. v0.9 adds optional
      explicit passive stiffness/damping with zero defaults, so legacy ideal-joint behavior is
      retained when kPassive=cPassive=0. Passive impedance is not muscle activation and is not
      a validated human tissue law until calibrated from an identified source.</p>
      </html>"));
    end Hip;

  
  end Joints;

