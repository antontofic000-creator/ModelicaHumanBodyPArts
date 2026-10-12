within ModelicaHumanBodyPArts;
  package CanonicalReplay
    "Historical scalar replays; not integrated human-body dynamics"
    extends Modelica.Icons.Package;
    annotation(Documentation(info="<html><p>Imported from the supplied v0.8 branch."
      + " Prescribed S45/S46 diagnostics are separate from the articulated body."
      + " Signed heel requirements outside [0,1] identify infeasibility."
      + " They are not admissible physical contact loads."
      + " See the Test Report for execution status and historical evidence.</p></html>"));
  
    function quinticKinematics
      "Prescribed quintic source trajectory, stationary before zero and after T"
      input Modelica.Units.SI.Time t;
      input Modelica.Units.SI.Length D;
      input Modelica.Units.SI.Time T;
      output Modelica.Units.SI.Position x;
      output Modelica.Units.SI.Velocity v;
      output Modelica.Units.SI.Acceleration a;
    protected
      Real u;
    algorithm
      assert(T > 0 and D >= 0, "Require T > 0 and D >= 0");
      u := min(1, max(0, t/T));
      x := D*(10*u^3 - 15*u^4 + 6*u^5);
      v := D/T*(30*u^2 - 60*u^3 + 30*u^4);
      a := D/T^2*(60*u - 180*u^2 + 120*u^3);
    end quinticKinematics;
  
    function s45Kinematics
      "Ankle first, then knee: archived S45 prescribed-point geometry"
      input Modelica.Units.SI.Position x;
      input Modelica.Units.SI.Length Ls=0.45 "Canonical reduced link, not anthropometry";
      input Modelica.Units.SI.Length Lu=1.15 "Knee to force-point link";
      input Modelica.Units.SI.Angle ankleMax=12*Modelica.Constants.pi/180;
      output Modelica.Units.SI.Angle qa;
      output Modelica.Units.SI.Angle qk;
    protected
      Real arg;
    algorithm
      assert(Ls > 0 and Lu > 0 and x >= 0 and x < Ls+Lu,
        "Invalid S45 geometry/domain");
      assert(ankleMax > 0 and ankleMax < Modelica.Constants.pi/2,
        "Ankle range must lie strictly between zero and pi/2");
      qa := min(asin(x/(Ls+Lu)), ankleMax);
      arg := (x-Ls*sin(qa))/Lu;
      assert(abs(arg) <= 1, "Knee-available geometry infeasible");
      qk := max(asin(arg)-qa, 0);
    end s45Kinematics;
  
    function s46Diagnostics
      "Historical S46 routing diagnostic, not closed Newton-Euler forward dynamics"
      input Modelica.Units.SI.Position x;
      input Modelica.Units.SI.Acceleration a;
      input Real beta(min=0)=0.05 "Resistance / body weight";
      input Modelica.Units.SI.Mass M=75;
      input Modelica.Units.SI.Acceleration g=9.81;
      input Modelica.Units.SI.Length h=1.60;
      input Modelica.Units.SI.Length zCOM=1.02
        "Reconstructed from archived support-force/COP history";
      input Modelica.Units.SI.Position xHeel=-0.09;
      input Modelica.Units.SI.Position xToe=0.15;
      output Modelica.Units.SI.Force upperForce;
      output Modelica.Units.SI.Angle ankleDemand;
      output Modelica.Units.SI.Position copUpper;
      output Modelica.Units.SI.Position copSupport;
      output Real heelDemandUpper "Signed requirement; negative means infeasible";
      output Real heelDemandSupport "Signed requirement; >1 means toe tension needed";
    algorithm
      assert(M > 0 and g > 0 and h > 0 and zCOM > 0 and beta >= 0,
        "Invalid S46 parameters");
      assert(xHeel < 0 and xToe > 0 and x >= 0 and x < h,
        "Invalid S46 contact geometry or inverse-sine domain");
      upperForce := max(M*a + beta*M*g, 0);
      ankleDemand := asin(x/h);
      copUpper := h*upperForce/(M*g);
      copSupport := -zCOM*upperForce/(M*g);
      heelDemandUpper := (xToe-copUpper)/(xToe-xHeel);
      heelDemandSupport := (xToe-copSupport)/(xToe-xHeel);
    end s46Diagnostics;
  
    model S45PrescribedReplay
      "Prescribed kinematic replay; no inertial or muscle dynamics"
      parameter Modelica.Units.SI.Length D=0.4;
      parameter Modelica.Units.SI.Time T=4;
      parameter Modelica.Units.SI.Length Ls=0.45;
      parameter Modelica.Units.SI.Length Lu=1.15;
      parameter Modelica.Units.SI.Angle ankleMax=12*Modelica.Constants.pi/180;
      Modelica.Units.SI.Position x;
      Modelica.Units.SI.Velocity v;
      Modelica.Units.SI.Acceleration a;
      Modelica.Units.SI.Angle qa;
      Modelica.Units.SI.Angle qk;
    equation
      (x,v,a)=quinticKinematics(time,D,T);
      (qa,qk)=s45Kinematics(x,Ls,Lu,ankleMax);
      annotation(experiment(StopTime=4,Interval=0.001,Tolerance=1e-8));
    end S45PrescribedReplay;
  
    model S46PrescribedReplay
      "Prescribed S46 diagnostics; first-sampled-event classification in Python runner"
      parameter Modelica.Units.SI.Length D=0.4;
      parameter Modelica.Units.SI.Time T=4;
      parameter Real beta=0.05;
      parameter Modelica.Units.SI.Angle ankleROM=12*Modelica.Constants.pi/180;
      parameter Modelica.Units.SI.Length h=1.60;
      parameter Modelica.Units.SI.Position xHeel=-0.09;
      parameter Modelica.Units.SI.Position xToe=0.15;
      Modelica.Units.SI.Position x,copUpper,copSupport;
      Modelica.Units.SI.Velocity v;
      Modelica.Units.SI.Acceleration a;
      Modelica.Units.SI.Angle ankleDemand,romMargin;
      Modelica.Units.SI.Force upperForce;
      Real heelDemandUpper,heelDemandSupport;
      Boolean heelBoundaryReached;
      Boolean romBoundaryReached;
    equation
      (x,v,a)=quinticKinematics(time,D,T);
      (upperForce,ankleDemand,copUpper,copSupport,heelDemandUpper,heelDemandSupport)=
        s46Diagnostics(x=x,a=a,beta=beta,h=h,xHeel=xHeel,xToe=xToe);
      romMargin=ankleROM-ankleDemand;
      heelBoundaryReached=copUpper >= xToe;
      romBoundaryReached=romMargin <= 0;
      annotation(experiment(StopTime=4,Interval=0.001,Tolerance=1e-8));
    end S46PrescribedReplay;
  
  end CanonicalReplay;

