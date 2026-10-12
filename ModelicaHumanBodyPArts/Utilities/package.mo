within ModelicaHumanBodyPArts;
  package Utilities
    extends Modelica.Icons.Package;
  
    function physicalInertia
      "Check symmetric positive I and nonnegative second mass moment (triangle inequalities)"
      input Real I[3,3];
      input Real relTol=1e-10;
      output Boolean valid;
    protected
      Real S[3,3]; Real J[3,3]; Real scale; Real symError; Real tr;
    algorithm
      scale := max(1e-30,max(abs(I)));
      J := I/scale;
      tr := J[1,1]+J[2,2]+J[3,3];
      symError := max(abs(J-transpose(J)));
      S := 0.5*tr*identity(3)-J;
      valid := symError<=relTol and J[1,1]>0 and
        J[1,1]*J[2,2]-J[1,2]^2>0 and Modelica.Math.Matrices.det(J)>0 and
        min({S[1,1],S[2,2],S[3,3]})>=-relTol and
        S[1,1]*S[2,2]-S[1,2]^2>=-relTol and
        S[1,1]*S[3,3]-S[1,3]^2>=-relTol and
        S[2,2]*S[3,3]-S[2,3]^2>=-relTol and
        Modelica.Math.Matrices.det(S)>=-relTol;
    end physicalInertia;
  
    function affineMassProperties
      "Mass-renormalized affine pushforward; exact for the assumed transformed density"
      import SI = Modelica.Units.SI;
      input SI.Mass massReference;
      input SI.Position rCMReference[3];
      input SI.Inertia inertiaReference[3,3];
      input Real A[3,3] "Invertible stretch/rotation map applied to all source points";
      input SI.Position b[3] "Translation of mapped points";
      input SI.Mass massTarget;
      output SI.Position rCM[3];
      output SI.Inertia I_CM[3,3];
    protected
      SI.Inertia S[3,3]; SI.Inertia Snew[3,3];
    algorithm
      assert(massReference>0 and massTarget>0, "Masses must be positive.");
      assert(abs(Modelica.Math.Matrices.det(A))>1e-12, "Affine map must be invertible.");
      assert(physicalInertia(inertiaReference), "Nonphysical source inertia.");
      S := 0.5*(inertiaReference[1,1]+inertiaReference[2,2]+inertiaReference[3,3])
        *identity(3)-inertiaReference;
      Snew := (massTarget/massReference)*A*S*transpose(A);
      rCM := A*rCMReference+b;
      I_CM := (Snew[1,1]+Snew[2,2]+Snew[3,3])*identity(3)-Snew;
      assert(physicalInertia(I_CM), "Nonphysical mapped inertia.");
      annotation(Inline=false, Documentation(info="<html><p>New project derivation from the second mass
      moment S=integral (r-c)(r-c)' dm. Handles unequal axial/cross-sectional scaling.
      It is NOT an empirically validated human allometry or population regression.</p></html>"));
    end affineMassProperties;
  
    function shiftInertia
      "Rotate COM inertia into a reporting frame, then shift to another origin"
      input Modelica.Units.SI.Inertia I_CM[3,3];
      input Real R[3,3] "Maps local vectors to reporting-frame vectors";
      input Modelica.Units.SI.Mass mass;
      input Modelica.Units.SI.Position d[3] "New origin to COM, in reporting frame";
      output Modelica.Units.SI.Inertia I_O[3,3];
    algorithm
      assert(mass>0, "Mass must be positive.");
      assert(max(abs(transpose(R)*R-identity(3)))<1e-9 and
        abs(Modelica.Math.Matrices.det(R)-1)<1e-9, "R must be a proper rotation.");
      I_O := R*I_CM*transpose(R)+mass*((d*d)*identity(3)-outerProduct(d,d));
    end shiftInertia;
  
  end Utilities;

