within;
model A2TwoInertiaBenchmark
  "Analytical two-inertia torsional benchmark for Article 2"
  import SI=Modelica.Units.SI;
  parameter SI.Inertia I1=1.2;
  parameter SI.Inertia I2=0.8;
  parameter SI.RotationalSpringConstant k=15;
  parameter SI.Angle delta0=0.10;
  parameter SI.AngularVelocity omega=sqrt(k*(1/I1+1/I2));
  SI.Angle q1(start=I2/(I1+I2)*delta0,fixed=true);
  SI.Angle q2(start=-I1/(I1+I2)*delta0,fixed=true);
  SI.AngularVelocity w1(start=0,fixed=true),w2(start=0,fixed=true);
  output SI.Angle delta=q1-q2;
  output SI.Angle analyticDelta=delta0*cos(omega*time);
  output SI.Angle analyticQ1=I2/(I1+I2)*analyticDelta;
  output SI.Angle analyticQ2=-I1/(I1+I2)*analyticDelta;
  output SI.Angle deltaError=delta-analyticDelta;
  output SI.Angle q1Error=q1-analyticQ1;
  output SI.Angle q2Error=q2-analyticQ2;
  output Integer checksPassed(start=0,fixed=true);
equation
  der(q1)=w1; der(q2)=w2;
  I1*der(w1)=-k*(q1-q2);
  I2*der(w2)= k*(q1-q2);
algorithm
  when time>=0.999 then
    assert(abs(deltaError)<2e-6 and abs(q1Error)<2e-6 and abs(q2Error)<2e-6,"Two-inertia analytical benchmark failed");
    checksPassed:=1;
  end when;
  annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-10,Interval=0.0005));
end A2TwoInertiaBenchmark;