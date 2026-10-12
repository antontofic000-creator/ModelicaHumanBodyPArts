within ModelicaHumanBodyPArts;
  package Sensors
    extends Modelica.Icons.SensorsPackage;
  
    model JointLimitMonitor
      "ROM utilization and limiting-DOF monitor; no torque generation in v0.2"
      import SI = Modelica.Units.SI;
    
      parameter Integer n(min=1)=1;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=n);
    
      input SI.Angle q[n];
    
      output SI.Angle marginLower[n];
      output SI.Angle marginUpper[n];
      output SI.Angle distanceToLimit[n];
      output Real utilization[n];
      output Integer limitingDOF(start=1)
        "Legacy name: nearest raw-angle margin, NOT proof of an active causal constraint";
      output Boolean atLimit[n];
      output Boolean violated[n];
      parameter SI.Angle activationTolerance=1e-9;
      parameter SI.Angle tieTolerance=1e-12
        "Tolerance for reporting near-equal nearest margins; does not change strict argmin";
      output Boolean nearestMarginTie[n];
      output Integer nearestMarginCount;
    
    protected
      SI.Angle center[n];
      SI.Angle halfRange[n];
    
    equation
      assert(activationTolerance>=0 and tieTolerance>=0, "Monitor tolerances must be nonnegative.");
      nearestMarginCount = sum({if nearestMarginTie[i] then 1 else 0 for i in 1:n});
      for i in 1:n loop
        nearestMarginTie[i] = abs(distanceToLimit[i]-min(distanceToLimit))<=tieTolerance;
        assert(mobility.qMax[i] > mobility.qMin[i],
          "Each joint upper ROM bound must be greater than the lower bound.");
    
        marginLower[i] = q[i] - mobility.qMin[i];
        marginUpper[i] = mobility.qMax[i] - q[i];
        distanceToLimit[i] = min(marginLower[i], marginUpper[i]);
        center[i] = 0.5*(mobility.qMin[i] + mobility.qMax[i]);
        halfRange[i] = 0.5*(mobility.qMax[i] - mobility.qMin[i]);
        utilization[i] = abs(q[i] - center[i])/halfRange[i];
        atLimit[i] = distanceToLimit[i]<=activationTolerance;
        violated[i] = distanceToLimit[i]<-activationTolerance;
      end for;
    
    algorithm
      limitingDOF := 1;
      for i in 2:n loop
        if distanceToLimit[i] < distanceToLimit[limitingDOF] then
          limitingDOF := i;
        end if;
      end for;
    end JointLimitMonitor;
  
  end Sensors;

