(******************************************************************************
 *                            KRAFT PHYSICS ENGINE                            *
 ******************************************************************************
 *                        Version 2015-06-18-23-28-0000                       *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (c) 2015, Benjamin Rosseaux (benjamin@rosseaux.de)               *
 *                                                                            *
 * This software is provided 'as-is', without any express or implied          *
 * warranty. In no event will the authors be held liable for any damages      *
 * arising from the use of this software.                                     *
 *                                                                            *
 * Permission is granted to anyone to use this software for any purpose,      *
 * including commercial applications, and to alter it and redistribute it     *
 * freely, subject to the following restrictions:                             *
 *                                                                            *
 * 1. The origin of this software must not be misrepresented; you must not    *
 *    claim that you wrote the original software. If you use this software    *
 *    in a product, an acknowledgement in the product documentation would be  *
 *    appreciated but is not required.                                        *
 * 2. Altered source versions must be plainly marked as such, and must not be *
 *    misrepresented as being the original software.                          *
 * 3. This notice may not be removed or altered from any source distribution. *
 *                                                                            *
 ******************************************************************************
 *                  General guidelines for code contributors                  *
 *============================================================================*
 *                                                                            *
 * 1. Make sure you are legally allowed to make a contribution under the zlib *
 *    license.                                                                *
 * 2. The zlib license header goes at the top of each source file, with       *
 *    appropriate copyright notice.                                           *
 * 3. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/kraft                                        *
 * 4. Write code, which is compatible with Delphi 7-XE7 and FreePascal >= 2.6 *
 *    so don't use generics/templates, operator overloading and another newer *
 *    syntax features than Delphi 7 has support for that.                     *    
 * 5. Don't use Delphi VCL, FreePascal FCL or Lazarus LCL libraries/units.    *
 * 6. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able                                                       *
 * 7. Try to use const when possible.                                         *
 * 8. Make sure to comment out writeln, used while debugging                  *
 * 9. Use TKraftScalar instead of float/double so that Kraft can be compiled  *
 *    as double/single precision.                                             *
 * 10. Make sure the code compiles on 32-bit and 64-bit platforms in single   *
 *     and double precision.                                                  *
 *                                                                            *
 ******************************************************************************)
unit kraft;
{$ifdef fpc}
 {$mode delphi}
 {$warnings off}
 {$hints off}
 {$define caninline}
 {$ifdef cpui386}
  {$define cpu386}
 {$endif}
 {$ifdef cpuamd64}
  {$define cpux86_64}
  {$define cpux64}
 {$else}
  {$ifdef cpux86_64}
   {$define cpuamd64}
   {$define cpux64}
  {$endif}
 {$endif}
 {$ifdef cpu386}
  {$define cpu386}
  {$asmmode intel}
  {$define canx86simd}
 {$endif}
 {$ifdef FPC_LITTLE_ENDIAN}
  {$define LITTLE_ENDIAN}
 {$else}
  {$ifdef FPC_BIG_ENDIAN}
   {$define BIG_ENDIAN}
  {$endif}
 {$endif}
{$else}
 {$define LITTLE_ENDIAN}
 {$ifndef cpu64}
  {$define cpu32}
 {$endif}
 {$safedivide off}
 {$optimization on}
 {$undef caninline}
 {$undef canx86simd}
 {$ifdef ver180}
  {$define caninline}
  {$ifdef cpu386}
   {$define canx86simd}
  {$endif}
  {$finitefloat off}
 {$endif}
{$endif}
{$ifdef win32}
 {$define windows}
{$endif}
{$ifdef win64}
 {$define windows}
{$endif}
{$extendedsyntax on}
{$writeableconst on}
{$varstringchecks on}
{$typedaddress off}
{$overflowchecks off}
{$rangechecks off}
{$ifndef fpc}
{$realcompatibility off}
{$endif}
{$openstrings on}
{$longstrings on}
{$booleval off}

{-$define UseMoreCollisionGroups}

{-$define DebugDraw}

{-$define memdebug}

{$ifdef UseDouble}
 {$define NonSIMD}
{$endif}

{-$define NonSIMD}

{$ifdef NonSIMD}
 {$undef CPU386ASMForSinglePrecision}
 {$undef SIMD}
{$else}
 {$ifdef cpu386}
  {$define CPU386ASMForSinglePrecision}
 {$endif}
 {$undef SIMD}
 {$ifdef CPU386ASMForSinglePrecision}
  {$define SIMD}
 {$endif}
{$endif}

interface

uses {$ifdef windows}
      Windows,
      MMSystem,
     {$else}
      {$ifdef unix}
       BaseUnix,
       Unix,
       UnixType,
       {$ifdef linux}
        linux,
       {$endif}
      {$else}
       SDL,
      {$endif}
     {$endif}
     {$ifdef DebugDraw}
      {$ifdef fpcGL}
       GL,
       GLext,
      {$else}
       OpenGL,
      {$endif}
     {$endif}
     SysUtils,
     Classes,
     SyncObjs,
     Math;

const EPSILON={$ifdef UseDouble}1e-14{$else}1e-5{$endif}; // actually {$ifdef UseDouble}1e-16{$else}1e-7{$endif}; but we are conservative here

      MAX_SCALAR={$ifdef UseDouble}1.7e+308{$else}3.4e+28{$endif};

      DEG2RAD=pi/180.0;
      RAD2DEG=180.0/PI;

      MAX_CONTACTS=4;             // After largest-area contact reduction

      MAX_TEMPORARY_CONTACTS=256; // Before largest-area contact reduction

      MAX_THREADS=32;

      MaxSATSupportVertices=64;
      MaxSATContacts=64;

      MPRTolerance=1e-3;

      MPRMaximumIterations=128;

      GJKTolerance=1e-4;

      GJKMaximumIterations=128;

      TimeOfImpactTolerance=1e-3;

      TimeOfImpactMaximumIterations=64;

      TimeOfImpactSphericalExpansionRadius=1e-5;

      PhysicsFPUPrecisionMode:TFPUPrecisionMode={$ifdef cpu386}pmExtended{$else}{$ifdef cpux64}pmExtended{$else}pmDouble{$endif}{$endif};

      PhysicsFPUExceptionMask:TFPUExceptionMask=[exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision];

type PKraftForceMode=^TKraftForceMode;
     TKraftForceMode=(kfmForce,        // The unit of the force parameter is applied to the rigidbody as mass*distance/time^2.
                      kfmAcceleration, // The unit of the force parameter is applied to the rigidbody as distance/time^2.
                      kfmImpulse,      // The unit of the force parameter is applied to the rigidbody as mass*distance/time.
                      kfmVelocity);    // The unit of the force parameter is applied to the rigidbody as distance/time.

     PKraftContinuousMode=^TKraftContinuousMode;
     TKraftContinuousMode=(kcmNone,                     // No continuous collision detection and response
                           kcmMotionClamping,           // Continuous collision detection and response with motion clamping
                           kcmTimeOfImpactSubSteps);    // Continuous collision detection and response with time of impact sub stepping

     PKraftTimeOfImpactAlgorithm=^TKraftTimeOfImpactAlgorithm;
     TKraftTimeOfImpactAlgorithm=(ktoiaConservativeAdvancement,       // Time of impact detection with conservative advancement
                                  ktoiaBilateralAdvancement);         // Time of impact detection with bilateral advancement

     PKraftContactFlag=^TKraftContactFlag;
     TKraftContactFlag=(kcfEnabled,       // To disable contacts by users and for internal usage for processing continuous collection detection
                        kcfColliding,     // Set when contact collides during a step
                        kcfWasColliding,  // Set when two objects stop colliding
                        kcfInIsland,      // For internal marking during island forming
                        kcfFiltered,      // For internal filering
                        kcfTimeOfImpact); // For internal marking during time of impact stuff

     PKraftContactFlags=^TKraftContactFlags;
     TKraftContactFlags=set of TKraftContactFlag;

     PKraftConstraintFlag=^TKraftConstraintFlag;
     TKraftConstraintFlag=(kcfCollideConnected,
                           kcfBreakable,
                           kcfActive,
                           kcfVisited,
                           kcfBreaked,
                           kcfFreshBreaked);

     PKraftConstraintFlags=^TKraftConstraintFlags;

     TKraftConstraintFlags=set of TKraftConstraintFlag;

     PKraftConstraintLimitBehavior=^TKraftConstraintLimitBehavior;
     TKraftConstraintLimitBehavior=(kclbLimitDistance,kclbLimitMaximumDistance,kclbLimitMinimumDistance);

     PKraftShapeType=^TKraftShapeType;
     TKraftShapeType=(kstUnknown=0,
                      kstSphere,
                      kstCapsule,
                      kstConvexHull,
                      kstBox,          // Internally derived from convex hull
                      kstPlane,        // Internally derived from convex hull
                      kstTriangle,     // Internally derived from convex hull and only for internal usage only at mesh shapes
                      kstMesh);        // Static only

     PKraftShapeFlag=^TKraftShapeFlag;
     TKraftShapeFlag=(ksfSensor);

     PKraftShapeFlags=^TKraftShapeFlags;
     TKraftShapeFlags=set of TKraftShapeFlag;

     PKraftRigidBodyType=^TKraftRigidBodyType;
     TKraftRigidBodyType=(krbtUnknown,
                          krbtStatic,
                          krbtDynamic,
                          krbtKinematic);

     PKraftRigidBodyFlag=^TKraftRigidBodyFlag;
     TKraftRigidBodyFlag=(krbfHasOwnGravity,
                          krbfContinuous,
                          krbfContinuousAgainstDynamics,
                          krbfAllowSleep,
                          krbfAwake,
                          krbfActive,
                          krbfLockAxisX,
                          krbfLockAxisY,
                          krbfLockAxisZ,
                          krbfSensor,
                          krbfIslandVisited,
                          krbfIslandStatic);

     PKraftRigidBodyFlags=^TKraftRigidBodyFlags;
     TKraftRigidBodyFlags=set of TKraftRigidBodyFlag;

     PKraftRigidBodyCollisionGroup=^TKraftRigidBodyCollisionGroup;
     TKraftRigidBodyCollisionGroup={$ifdef UseMoreCollisionGroups}0..255{$else}0..31{$endif};

     PKraftRigidBodyCollisionGroups=^TKraftRigidBodyCollisionGroup;
     TKraftRigidBodyCollisionGroups=set of TKraftRigidBodyCollisionGroup;

     EKraftShapeTypeOnlyForStaticRigidBody=class(Exception);

     EKraftCorruptMeshData=class(Exception);

     EKraftDegeneratedConvexHull=class(Exception);

     TKraft=class;

     TKraftContactManager=class;

     TKraftIsland=class;

     TKraftShape=class;

     TKraftRigidBody=class;

     TKraftHighResolutionTimer=class
      public
       Frequency:int64;
       FrequencyShift:longint;
       FrameInterval:int64;
       MillisecondInterval:int64;
       TwoMillisecondsInterval:int64;
       FourMillisecondsInterval:int64;
       QuarterSecondInterval:int64;
       HourInterval:int64;
       constructor Create(FrameRate:longint=60);
       destructor Destroy; override;
       procedure SetFrameRate(FrameRate:longint);
       function GetTime:int64;
       function GetEventTime:int64;
       procedure Sleep(Delay:int64);
       function ToFixedPointSeconds(Time:int64):int64;
       function ToFixedPointFrames(Time:int64):int64;
       function ToFloatSeconds(Time:int64):double;
       function FromFloatSeconds(Time:double):int64;
       function ToMilliseconds(Time:int64):int64;
       function FromMilliseconds(Time:int64):int64;
       function ToMicroseconds(Time:int64):int64;
       function FromMicroseconds(Time:int64):int64;
       function ToNanoseconds(Time:int64):int64;
       function FromNanoseconds(Time:int64):int64;
       property SecondInterval:int64 read Frequency;
     end;

     PKraftScalar=^TKraftScalar;
     TKraftScalar={$ifdef UseDouble}double{$else}single{$endif};

     PKraftColor=^TKraftColor;
     TKraftColor=record
      r,g,b,a:TKraftScalar;
     end;

     PKraftAngles=^TKraftAngles;
     TKraftAngles=record
      Pitch,Yaw,Roll:TKraftScalar;
     end;

     PKraftVector2=^TKraftVector2;
     TKraftVector2=record
      x,y:TKraftScalar;
     end;

     PKraftRawVector3=^TKraftRawVector3;
     TKraftRawVector3=record
      case byte of
       0:(x,y,z:TKraftScalar);
       1:(xyz:array[0..2] of TKraftScalar);
     end;

     PKraftVector3=^TKraftVector3;
     TKraftVector3=record
      case byte of
       0:(x,y,z{$ifdef SIMD},w{$endif}:TKraftScalar);
       1:(Pitch,Yaw,Roll:single);
       2:(xyz:array[0..2] of TKraftScalar);
       3:(PitchYawRoll:array[0..2] of single);
       4:(RawVector:TKraftRawVector3);
{$ifdef SIMD}
       5:(xyzw:array[0..3] of TKraftScalar);
{$endif}
     end;

     PKraftVector4=^TKraftVector4;
     TKraftVector4=record
      case byte of
       0:(x,y,z,w:TKraftScalar);
       1:(xyz:array[0..2] of TKraftScalar);
       2:(xyzw:array[0..3] of TKraftScalar);
     end;

     TKraftVector3Array=array of TKraftVector3;

     PKraftVector3s=^TKraftVector3s;
     TKraftVector3s=array[0..$ff] of TKraftVector3;

     PPKraftVector3s=^TPKraftVector3s;
     TPKraftVector3s=array[0..$ff] of PKraftVector3;

     PKraftPlane=^TKraftPlane;
     TKraftPlane=record
      Normal:TKraftVector3;
      Distance:TKraftScalar;
     end;

     PKraftQuaternion=^TKraftQuaternion;
     TKraftQuaternion=record
      x,y,z,w:TKraftScalar;
     end;

     PKraftMatrix2x2=^TKraftMatrix2x2;
     TKraftMatrix2x2=array[0..1,0..1] of TKraftScalar;

     PKraftMatrix3x3=^TKraftMatrix3x3;
     TKraftMatrix3x3=array[0..2,0..{$ifdef SIMD}3{$else}2{$endif}] of TKraftScalar;

     PKraftMatrix4x4=^TKraftMatrix4x4;
     TKraftMatrix4x4=array[0..3,0..3] of TKraftScalar;

     PKraftAABB=^TKraftAABB;
     TKraftAABB=record
      case boolean of
       false:(
        Min,Max:TKraftVector3;
       );
       true:(
        MinMax:array[0..1] of TKraftVector3;
       );
     end;

     PKraftAABBs=^TKraftAABBs;
     TKraftAABBs=array[0..65535] of TKraftAABB;

     PKraftSphere=^TKraftSphere;
     TKraftSphere=record
      Center:TKraftVector3;
      Radius:TKraftScalar;
     end;

     PKraftSpheres=^TKraftSpheres;
     TKraftSpheres=array[0..65535] of TKraftSphere;

     PKraftSegment=^TKraftSegment;
     TKraftSegment=record
      Points:array[0..1] of TKraftVector3;
     end;

     PKraftRelativeSegment=^TKraftRelativeSegment;
     TKraftRelativeSegment=record
      Origin:TKraftVector3;
      Delta:TKraftVector3;
     end;

     PKraftTriangle=^TKraftTriangle;
     TKraftTriangle=record
      Points:array[0..2] of TKraftVector3;
      Normal:TKraftVector3;
     end;

     PKraftTimeStep=^TKraftTimeStep;
     TKraftTimeStep=record
      DeltaTime:TKraftScalar;
      InverseDeltaTime:TKraftScalar;
      DeltaTimeRatio:TKraftScalar;
      WarmStarting:longbool;
     end;

     PKraftDynamicAABBTreeNode=^TKraftDynamicAABBTreeNode;
     TKraftDynamicAABBTreeNode=record
      AABB:TKraftAABB;
      UserData:pointer;
      Children:array[0..1] of longint;
      Height:longint;
      case boolean of
       false:(
        Parent:longint;
       );
       true:(
        Next:longint;
       );
     end;

     PKraftDynamicAABBTreeNodes=^TKraftDynamicAABBTreeNodes;
     TKraftDynamicAABBTreeNodes=array[0..0] of TKraftDynamicAABBTreeNode;

     PKraftDynamicAABBTreeLongintArray=^TKraftDynamicAABBTreeLongintArray;
     TKraftDynamicAABBTreeLongintArray=array[0..65535] of longint;

     TKraftDynamicAABBTree=class
      public
       Root:longint;
       Nodes:PKraftDynamicAABBTreeNodes;
       NodeCount:longint;
       NodeCapacity:longint;
       FreeList:longint;
       Path:longword;
       InsertionCount:longint;
       Stack:PKraftDynamicAABBTreeLongintArray;
       StackCapacity:longint;
       constructor Create;
       destructor Destroy; override;
       function AllocateNode:longint;
       procedure FreeNode(NodeID:longint);
       function Balance(NodeAID:longint):longint;
       procedure InsertLeaf(Leaf:longint);
       procedure RemoveLeaf(Leaf:longint);
       function CreateProxy(const AABB:TKraftAABB;UserData:pointer):longint;
       procedure DestroyProxy(NodeID:longint);
       function MoveProxy(NodeID:longint;const AABB:TKraftAABB;const Displacement,BoundsExpansion:TKraftVector3):boolean;
       procedure Rebalance(Iterations:longint);
       procedure Rebuild;
       function ComputeHeight:longint;
       function GetHeight:longint;
       function GetAreaRatio:TKraftScalar;
       function GetMaxBalance:longint;
       function ValidateStructure:boolean;
       function ValidateMetrics:boolean;
       function Validate:boolean;
       function GetIntersectionProxy(const AABB:TKraftAABB):pointer;
     end;

     PKraftSweep=^TKraftSweep;
     TKraftSweep=record
      LocalCenter:TKraftVector3; // Center of mass in local space
      c0,c:TKraftVector3;        // Center of mass in world space
      q0,q:TKraftQuaternion;     // Rotation/Orientation
      Alpha0:TKraftScalar;       // Fraction of timestep from [0, 1]; c0, and q0 are at Alpha0
     end;

     PKraftMassData=^TKraftMassData;
     TKraftMassData=object
      public
       Inertia:TKraftMatrix3x3;
       Center:TKraftVector3;
       Mass:TKraftScalar;
       Volume:TKraftScalar;
       Count:longint;
       procedure Adjust(const NewMass:TKraftScalar);
       procedure Add(const WithMassData:TKraftMassData);
       procedure Rotate(const WithMatrix:TKraftMatrix3x3);
       procedure Translate(const WithVector:TKraftVector3);
       procedure Transform(const WithMatrix:TKraftMatrix4x4);
     end;

     TKraftConvexHullVertexList=class
      public
       Vertices:array of TKraftVector3;
       Capacity:longint;
       Count:longint;
       Color:TKraftColor;
       constructor Create;
       destructor Destroy; override;
       procedure Clear;
       procedure Add(const v:TKraftVector3);
     end;

     PKraftRaycastData=^TKraftRaycastData;
     TKraftRaycastData=record
      Origin:TKraftVector3;
      Direction:TKraftVector3;
      MaxTime:TKraftScalar;
      TimeOfImpact:TKraftScalar;
      Point:TKraftVector3;
      Normal:TKraftVector3;
     end;

     PKraftConvexHullVertex=^TKraftConvexHullVertex;
     TKraftConvexHullVertex=record
      Position:TKraftVector3;
      CountAdjacencies:longint;
      Adjacencies:array[0..6] of longint;
     end;

     PPKraftConvexHullVertices=^TPKraftConvexHullVertices;
     TPKraftConvexHullVertices=array[0..65535] of TKraftConvexHullVertex;

     TKraftConvexHullVertices=array of TKraftConvexHullVertex;

     PKraftConvexHullFace=^TKraftConvexHullFace;
     TKraftConvexHullFace=record
      Plane:TKraftPlane;
      Vertices:array of longint;
      CountVertices:longint;
      EdgeVertexOffset:longint;
     end;

     TKraftConvexHullFaces=array of TKraftConvexHullFace;

     PKraftConvexHullEdge=^TKraftConvexHullEdge;
     TKraftConvexHullEdge=record
      Vertices:array[0..1] of longint;
      Faces:array[0..1] of longint;
     end;

     TKraftConvexHullEdges=array of TKraftConvexHullEdge;

     TKraftConvexHull=class
      private

       procedure CalculateMassData;

       procedure CalculateCentroid;

      public

       Physics:TKraft;

       Previous:TKraftConvexHull;
       Next:TKraftConvexHull;

       Vertices:TKraftConvexHullVertices;
       CountVertices:longint;

       Faces:TKraftConvexHullFaces;
       CountFaces:longint;

       Edges:TKraftConvexHullEdges;
       CountEdges:longint;

       Sphere:TKraftSphere;

       AABB:TKraftAABB;

       AngularMotionDisc:TKraftScalar;

       MassData:TKraftMassData;

       Centroid:TKraftVector3;

       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;

       function AddVertex(const AVertex:TKraftVector3):longint;

       procedure Load(const AVertices:PKraftVector3;const ACountVertices:longint);

       procedure Scale(const WithFactor:TKraftScalar); overload;
       procedure Scale(const WithVector:TKraftVector3); overload;

       procedure Transform(const WithMatrix:TKraftMatrix3x3); overload;
       procedure Transform(const WithMatrix:TKraftMatrix4x4); overload;

       procedure Build(const AMaximumCountConvexHullPoints:longint=-1);

       procedure Update;

       procedure Finish;

       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;

       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;

       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;

     end;

     PKraftMeshTriangle=^TKraftMeshTriangle;
     TKraftMeshTriangle=record
      Next:longint;
      Vertices:array[0..2] of longint;
      Normals:array[0..2] of longint;
      Plane:TKraftPlane;
      AABB:TKraftAABB;
     end;

     TKraftMeshTriangles=array of TKraftMeshTriangle;

     PKraftMeshSkipListNode=^TKraftMeshSkipListNode;
     TKraftMeshSkipListNode=record
      SkipToNodeIndex:longint;
      TriangleIndex:longint;
      AABB:TKraftAABB;
     end;

     TKraftMeshSkipListNodes=array of TKraftMeshSkipListNode;

     TKraftMesh=class
      private

       procedure CalculateNormals;

      public

       Physics:TKraft;

       Previous:TKraftMesh;
       Next:TKraftMesh;

       Vertices:array of TKraftVector3;
       CountVertices:longint;

       Normals:array of TKraftVector3;
       CountNormals:longint;

       Triangles:TKraftMeshTriangles;
       CountTriangles:longint;

       SkipListNodes:TKraftMeshSkipListNodes;
       CountSkipListNodes:longint;

       AABB:TKraftAABB;

       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;

       function AddVertex(const AVertex:TKraftVector3):longint;

       function AddNormal(const ANormal:TKraftVector3):longint;

       function AddTriangle(const AVertexIndex0,AVertexIndex1,AVertexIndex2:longint;const ANormalIndex0:longint=-1;const ANormalIndex1:longint=-1;ANormalIndex2:longint=-1):longint;

       procedure Load(const AVertices:PKraftVector3;const ACountVertices:longint;const ANormals:PKraftVector3;const ACountNormals:longint;const AVertexIndices,ANormalIndices:pointer;const ACountIndices:longint); overload;
       procedure Load(const ASourceData:pointer;const ASourceSize:longint); overload;

       procedure Scale(const WithFactor:TKraftScalar); overload;
       procedure Scale(const WithVector:TKraftVector3); overload;

       procedure Transform(const WithMatrix:TKraftMatrix3x3); overload;
       procedure Transform(const WithMatrix:TKraftMatrix4x4); overload;

       procedure Finish;

     end;

     PKraftContactPair=^TKraftContactPair;

     TKraftShapeOnContactBeginHook=procedure(const ContactPair:PKraftContactPair;const WithShape:TKraftShape) of object;
     TKraftShapeOnContactEndHook=procedure(const ContactPair:PKraftContactPair;const WithShape:TKraftShape) of object;
     TKraftShapeOnContactStayHook=procedure(const ContactPair:PKraftContactPair;const WithShape:TKraftShape) of object;

     TKraftShape=class
      private

{$ifdef DebugDraw}
       DrawDisplayList:glUint;
{$endif}

       IsMesh:longbool;

      public

       Physics:TKraft;

       RigidBody:TKraftRigidBody;

       ShapeType:TKraftShapeType;

       ShapePrevious:TKraftShape;
       ShapeNext:TKraftShape;

       Flags:TKraftShapeFlags;

       Friction:TKraftScalar;

       Restitution:TKraftScalar;

       Density:TKraftScalar;

       UserData:pointer;

       StaticAABBTreeProxy:longint;
       SleepingAABBTreeProxy:longint;
       DynamicAABBTreeProxy:longint;
       KinematicAABBTreeProxy:longint;

       ShapeAABB:TKraftAABB;

       ShapeSphere:TKraftSphere;

       WorldAABB:TKraftAABB;

       LastWorldAABB:TKraftAABB;

       LocalTransform:TKraftMatrix4x4;

       LocalCenterOfMass:TKraftVector3;

       LocalCentroid:TKraftVector3;

       WorldTransform:TKraftMatrix4x4;

       LastWorldTransform:TKraftMatrix4x4;

       InterpolatedWorldTransform:TKraftMatrix4x4;

       MassData:TKraftMassData;

       AngularMotionDisc:TKraftScalar;

       FeatureRadius:TKraftScalar;

       ContinuousMinimumRadiusScaleFactor:TKraftScalar;

       OnContactBegin:TKraftShapeOnContactBeginHook;
       OnContactEnd:TKraftShapeOnContactEndHook;
       OnContactStay:TKraftShapeOnContactStayHook;

       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody);
       destructor Destroy; override;

       procedure UpdateShapeAABB; virtual;

       procedure FillMassData(BodyInertiaTensor:TKraftMatrix3x3;const LocalTransform:TKraftMatrix4x4;const Mass,Volume:TKraftScalar); virtual;

       procedure CalculateMassData; virtual;

       procedure SynchronizeTransform; virtual;

       procedure SynchronizeProxies; virtual;

       procedure Finish; virtual;

       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; virtual;

       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; virtual;

       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; virtual;

       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; virtual;

       function TestPoint(const p:TKraftVector3):boolean; virtual;

       function RayCast(var RayCastData:TKraftRaycastData):boolean; virtual;

       procedure StoreWorldTransform; virtual;

       procedure InterpolateWorldTransform(const Alpha:TKraftScalar); virtual;

{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); virtual;
{$endif}

     end;

     TKraftShapeSphere=class(TKraftShape)
      public
       Radius:TKraftScalar;
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const ARadius:TKraftScalar); reintroduce;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

     TKraftShapeCapsule=class(TKraftShape)
      public
       Radius:TKraftScalar;
       Height:TKraftScalar;
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const ARadius,AHeight:TKraftScalar); reintroduce;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

     TKraftShapeConvexHull=class(TKraftShape)
      public
       ConvexHull:TKraftConvexHull;
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AConvexHull:TKraftConvexHull); reintroduce; overload;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

     TKraftShapeBox=class(TKraftShapeConvexHull)
      private
       ShapeConvexHull:TKraftConvexHull;
      public
       Extents:TKraftVector3;
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AExtents:TKraftVector3); reintroduce;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

     TKraftShapePlane=class(TKraftShapeConvexHull)
      private
       ShapeConvexHull:TKraftConvexHull;
       PlaneVertices:array[0..3] of TKraftVector3;
       PlaneCenter:TKraftVector3;
      public
       Plane:TKraftPlane;
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const APlane:TKraftPlane); reintroduce;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

     TKraftShapeMesh=class(TKraftShape)
      public
       Mesh:TKraftMesh;
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AMesh:TKraftMesh); reintroduce;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

     PKraftGJKStateShapes=^TKraftGJKStateShapes;
     TKraftGJKStateShapes=array[0..1] of TKraftShape;

     PKraftGJKStateTransforms=^TKraftGJKStateTransforms;
     TKraftGJKStateTransforms=array[0..1] of PKraftMatrix4x4;

     PKraftGJKSimplexVertex=^TKraftGJKSimplexVertex;
     TKraftGJKSimplexVertex=record
      sA:TKraftVector3;
      sB:TKraftVector3;
      w:TKraftVector3;
      a:TKraftScalar;
      iA:longint;
      iB:longint;
      Dummy:longint;
     end;

     PKraftGJKSimplexVertices=^TKraftGJKSimplexVertices;
     TKraftGJKSimplexVertices=array[0..3] of TKraftGJKSimplexVertex;

     PPKraftGJKSimplexVertices=^PKraftGJKSimplexVertices;
     TPKraftGJKSimplexVertices=array[0..3] of PKraftGJKSimplexVertex;

     PKraftGJKCachedSimplexVertex=^TKraftGJKCachedSimplexVertex;
     TKraftGJKCachedSimplexVertex=record
      a:TKraftScalar;
      iA:longint;
      iB:longint;
      Dummy:longint;
     end;

     PKraftGJKCachedSimplexVertices=^TKraftGJKCachedSimplexVertices;
     TKraftGJKCachedSimplexVertices=array[0..3] of TKraftGJKCachedSimplexVertex;

     PKraftGJKCachedSimplex=^TKraftGJKCachedSimplex;
     TKraftGJKCachedSimplex=record
      Vertices:TKraftGJKCachedSimplexVertices;
      Count:longint;
      Metric:TKraftScalar;
     end;

     PKraftGJKSimplex=^TKraftGJKSimplex;
     TKraftGJKSimplex=record
      VerticesData:TKraftGJKSimplexVertices;
      Vertices:TPKraftGJKSimplexVertices;
      Divisor:TKraftScalar;
      Count:longint;
     end;

     PKraftGJKClosestPoints=^TKraftGJKClosestPoints;
     TKraftGJKClosestPoints=array[0..1] of TKraftVector3;

     PKraftGJK=^TKraftGJK;
     TKraftGJK=object
      public
       Distance:TKraftScalar;
       Iterations:longint;
       UseRadii:longbool;
       Failed:longbool;
       Normal:TKraftVector3;
       ClosestPoints:TKraftGJKClosestPoints;
       Simplex:TKraftGJKSimplex;
       CachedSimplex:PKraftGJKCachedSimplex;
       Shapes:TKraftGJKStateShapes;
       Transforms:TKraftGJKStateTransforms;
       function Run:boolean;
     end;

     PKraftContactFeaturePair=^TKraftContactFeaturePair;
     TKraftContactFeaturePair=packed record
      case longint of
       0:(
        EdgeA:byte;
        FaceA:byte;
        EdgeB:byte;
        FaceB:byte;
       );
       1:(
        Key:longword;
       );
     end;

     PKraftContact=^TKraftContact;
     TKraftContact=record
      LocalPoints:array[0..1] of TKraftVector3;
      Penetration:TKraftScalar; // Only needed for contact reduction
      NormalImpulse:TKraftScalar;
      TangentImpulse:array[0..1] of TKraftScalar;
      Bias:TKraftScalar;
      NormalMass:TKraftScalar;
      TangentMass:array[0..1] of TKraftScalar;
      FeaturePair:TKraftContactFeaturePair;
      WarmStartState:longword;
     end;

     PKraftContacts=^TKraftContacts;
     TKraftContacts=array[0..65536] of TKraftContact;

     PKraftContactFaceQuery=^TKraftContactFaceQuery;
     TKraftContactFaceQuery=record
      Index:longint;
      Separation:TKraftScalar;
     end;

     PKraftContactEdgeQuery=^TKraftContactEdgeQuery;
     TKraftContactEdgeQuery=record
      IndexA:longint;
      IndexB:longint;
      Separation:TKraftScalar;
      Normal:TKraftVector3;
     end;

     PKraftSolverContact=^TKraftSolverContact;
     TKraftSolverContact=record
      Separation:TKraftScalar;
      Point:TKraftVector3;
     end;

     PKraftSolverContactManifold=^TKraftSolverContactManifold;
     TKraftSolverContactManifold=record
      CountContacts:longint;
      Contacts:array[0..MAX_CONTACTS-1] of TKraftSolverContact;
      Points:array[0..1] of TKraftVector3;
      Normal:TKraftVector3;
     end;

     PKraftContactManifoldType=^TKraftContactManifoldType;
     TKraftContactManifoldType=(kcmtUnknown,
                                        kcmtImplicit,
                                        kcmtFaceA,
                                        kcmtFaceB,
                                        kcmtEdges,
                                        kcmtImplicitEdge,
                                        kcmtImplicitNormal);

     PKraftContactManifold=^TKraftContactManifold;
     TKraftContactManifold=record
      ContactManifoldType:TKraftContactManifoldType;
      HaveData:longbool;
      CountContacts:longint;
      LocalRadius:array[0..1] of TKraftScalar;
      LocalNormal:TKraftVector3;
      TangentVectors:array[0..1] of TKraftVector3;
      Contacts:array[0..MAX_CONTACTS-1] of TKraftContact;
      FaceQueryAB:TKraftContactFaceQuery;
      FaceQueryBA:TKraftContactFaceQuery;
      EdgeQuery:TKraftContactEdgeQuery;
     end;

     PKraftContactPairEdge=^TKraftContactPairEdge;
     TKraftContactPairEdge=record
      Previous:PKraftContactPairEdge;
      Next:PKraftContactPairEdge;
      OtherRigidBody:TKraftRigidBody;
      ContactPair:PKraftContactPair;
     end;

     TKraftMeshContactPair=class;

     TKraftContactPair=object
      public
       Previous:PKraftContactPair;
       Next:PKraftContactPair;
       HashBucket:longint;
       HashPrevious:PKraftContactPair;
       HashNext:PKraftContactPair;
       Island:TKraftIsland;
       Shapes:array[0..1] of TKraftShape;
       ElementIndex:longint;
       MeshContactPair:TKraftMeshContactPair;
       RigidBodies:array[0..1] of TKraftRigidBody;
       Edges:array[0..1] of TKraftContactPairEdge;
       Friction:TKraftScalar;
       Restitution:TKraftScalar;
       Manifold:TKraftContactManifold;
       Flags:TKraftContactFlags;
       TimeOfImpactCount:longint;
       TimeOfImpact:TKraftScalar;
       procedure GetSolverContactManifold(out SolverContactManifold:TKraftSolverContactManifold;const WorldTransformA,WorldTransformB:TKraftMatrix4x4;PositionSolving:boolean);
       procedure DetectCollisions(const ContactManager:TKraftContactManager;const TriangleShape:TKraftShape=nil;const ThreadIndex:longint=0);
     end;

     TPKraftContactPairs=array of PKraftContactPair;

     TKraftContactManagerOnContactBeginHook=procedure(const ContactPair:PKraftContactPair) of object;
     TKraftContactManagerOnContactEndHook=procedure(const ContactPair:PKraftContactPair) of object;
     TKraftContactManagerOnContactStayHook=procedure(const ContactPair:PKraftContactPair) of object;

     PKraftContactIndices=^TKraftContactIndices;
     TKraftContactIndices=array[0..MAX_CONTACTS-1] of longint;

     TKraftMeshContactPair=class
      public

       ContactManager:TKraftContactManager;

       Previous:TKraftMeshContactPair;
       Next:TKraftMeshContactPair;

       HashBucket:longint;
       HashPrevious:TKraftMeshContactPair;
       HashNext:TKraftMeshContactPair;

       IsOnFreeList:longbool;

       Flags:TKraftContactFlags;

       ShapeConvex:TKraftShape;
       ShapeMesh:TKraftShape;

       RigidBodyConvex:TKraftRigidBody;
       RigidBodyMesh:TKraftRigidBody;

       ConvexAABBInMeshLocalSpace:TKraftAABB;

       constructor Create(const AContactManager:TKraftContactManager);
       destructor Destroy; override;
       procedure AddToHashTable; {$ifdef caninline}inline;{$endif}
       procedure RemoveFromHashTable; {$ifdef caninline}inline;{$endif}
       procedure MoveToFreeList;
       procedure MoveFromFreeList;
       procedure Query;
       procedure Update;
     end;

     PKraftMeshContactPairHashTableBucket=^TKraftMeshContactPairHashTableBucket;
     TKraftMeshContactPairHashTableBucket=record
      First:TKraftMeshContactPair;
      Last:TKraftMeshContactPair;
     end;

     TKraftMeshContactPairHashTable=array[0..(1 shl 16)-1] of TKraftMeshContactPairHashTableBucket;

     PKraftContactPairHashTableBucket=^TKraftContactPairHashTableBucket;
     TKraftContactPairHashTableBucket=record
      First:PKraftContactPair;
      Last:PKraftContactPair;
     end;

     TKraftContactPairHashTable=array[0..(1 shl 16)-1] of TKraftContactPairHashTableBucket;

     TKraftContactManagerOnCanCollide=function(const AShapeA,AShapeB:TKraftShape):boolean of object;

     PKraftContactManagerMeshTriangleContactQueueItem=^TKraftContactManagerMeshTriangleContactQueueItem;
     TKraftContactManagerMeshTriangleContactQueueItem=record
      MeshContactPair:TKraftMeshContactPair;
      TriangleIndex:longint;
     end;

     TKraftContactManagerMeshTriangleContactQueueItems=array of TKraftContactManagerMeshTriangleContactQueueItem;

     TKraftContactManager=class
      public

       Physics:TKraft;

       ContactPairFirst:PKraftContactPair;
       ContactPairLast:PKraftContactPair;

       FreeContactPairs:PKraftContactPair;

       CountContactPairs:longint;

       MeshContactPairFirst:TKraftMeshContactPair;
       MeshContactPairLast:TKraftMeshContactPair;

       MeshContactPairFirstFree:TKraftMeshContactPair;
       MeshContactPairLastFree:TKraftMeshContactPair;

       CountMeshContactPairs:longint;

       OnContactBegin:TKraftContactManagerOnContactBeginHook;
       OnContactEnd:TKraftContactManagerOnContactEndHook;
       OnContactStay:TKraftContactManagerOnContactStayHook;

       OnCanCollide:TKraftContactManagerOnCanCollide;

       ConvexHullVertexLists:array[0..MAX_THREADS-1,0..1] of TKraftConvexHullVertexList;

{$ifdef DebugDraw}
       DebugConvexHullVertexLists:array[0..255] of TKraftConvexHullVertexList;
       CountDebugConvexHullVertexLists:longint;
{$endif}

       TemporaryContacts:array[0..MAX_THREADS-1,0..MAX_TEMPORARY_CONTACTS-1] of TKraftContact;
       CountTemporaryContacts:array[0..MAX_THREADS-1] of longint;

       ActiveContactPairs:array of PKraftContactPair;
       CountActiveContactPairs:longint;
       CountRemainActiveContactPairsToDo:longint;

       MeshTriangleContactQueueItems:TKraftContactManagerMeshTriangleContactQueueItems;
       CountMeshTriangleContactQueueItems:longint;

       ConvexConvexContactPairHashTable:TKraftContactPairHashTable;

       ConvexMeshTriangleContactPairHashTable:TKraftContactPairHashTable;

       MeshContactPairHashTable:TKraftMeshContactPairHashTable;

       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;

       function HasDuplicateContact(const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AShapeA,AShapeB:TKraftShape;const AElementIndex:longint=-1):boolean;

       procedure AddConvexContact(const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AShapeA,AShapeB:TKraftShape;const AElementIndex:longint=-1;const AMeshContactPair:TKraftMeshContactPair=nil);

       procedure AddMeshContact(const ARigidBodyConvex,ARigidBodyMesh:TKraftRigidBody;const AShapeConvex,AShapeMesh:TKraftShape);

       procedure AddContact(const AShapeA,AShapeB:TKraftShape);

       procedure RemoveContact(AContactPair:PKraftContactPair);

       procedure RemoveMeshContact(AMeshContactPair:TKraftMeshContactPair);

       procedure RemoveContactsFromRigidBody(ARigidBody:TKraftRigidBody);

       procedure DoBroadPhase;

       procedure DoMidPhase;

       procedure ProcessContactPair(const ContactPair:PKraftContactPair;const ThreadIndex:longint=0);

       procedure ProcessContactPairJob(const JobIndex,ThreadIndex:longint);

       procedure DoNarrowPhase;

{$ifdef DebugDraw}
       procedure DebugDraw(const CameraMatrix:TKraftMatrix4x4);
{$endif}

       function ReduceContacts(const AInputContacts:PKraftContacts;const ACountInputContacts:longint;const AOutputContacts:PKraftContacts):longint;

       function GetMaximizedAreaReducedContactIndices(const AInputContactPositions:PPKraftVector3s;const ACountInputContactPositions:longint;var AOutputContactIndices:TKraftContactIndices):longint;

     end;

     PKraftBroadPhaseContactPair=^TKraftBroadPhaseContactPair;
     TKraftBroadPhaseContactPair=array[0..1] of TKraftShape;

     TKraftBroadPhaseContactPairs=array of TKraftBroadPhaseContactPair;

     TKraftBroadPhase=class
      public

       Physics:TKraft;

       ContactPairs:TKraftBroadPhaseContactPairs;
       CountContactPairs:longint;

       StaticMoveBuffer:array of longint;
       StaticMoveBufferSize:longint;

       SleepingMoveBuffer:array of longint;
       SleepingMoveBufferSize:longint;

       DynamicMoveBuffer:array of longint;
       DynamicMoveBufferSize:longint;

       KinematicMoveBuffer:array of longint;
       KinematicMoveBufferSize:longint;

       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;

       procedure UpdatePairs; {$ifdef caninline}inline;{$endif}

       procedure StaticBufferMove(ProxyID:longint); {$ifdef caninline}inline;{$endif}
       procedure SleepingBufferMove(ProxyID:longint); {$ifdef caninline}inline;{$endif}
       procedure DynamicBufferMove(ProxyID:longint); {$ifdef caninline}inline;{$endif}
       procedure KinematicBufferMove(ProxyID:longint); {$ifdef caninline}inline;{$endif}

     end;

     TKraftRigidBodyOnDamping=procedure(const RigidBody:TKraftRigidBody;const TimeStep:TKraftTimeStep) of object;

     TKraftRigidBodyOnStep=procedure(const RigidBody:TKraftRigidBody;const TimeStep:TKraftTimeStep) of object;

     TKraftConstraint=class;

     PKraftConstraintEdge=^TKraftConstraintEdge;
     TKraftConstraintEdge=record
      Previous:PKraftConstraintEdge;
      Next:PKraftConstraintEdge;
      Constraint:TKraftConstraint;
      OtherRigidBody:TKraftRigidBody;
     end;

     TKraftRigidBody=class
      private
       function GetAngularMomentum:TKraftVector3;
       procedure SetAngularMomentum(const NewAngularMomentum:TKraftVector3);
      public

       Physics:TKraft;

       Island:TKraftIsland;

       IslandIndices:array of longint;

       ID:uint64;

       RigidBodyType:TKraftRigidBodyType;

       RigidBodyPrevious:TKraftRigidBody;
       RigidBodyNext:TKraftRigidBody;

       StaticRigidBodyIsOnList:longbool;
       StaticRigidBodyPrevious:TKraftRigidBody;
       StaticRigidBodyNext:TKraftRigidBody;

       DynamicRigidBodyIsOnList:longbool;
       DynamicRigidBodyPrevious:TKraftRigidBody;
       DynamicRigidBodyNext:TKraftRigidBody;

       KinematicRigidBodyIsOnList:longbool;
       KinematicRigidBodyPrevious:TKraftRigidBody;
       KinematicRigidBodyNext:TKraftRigidBody;

       ShapeFirst:TKraftShape;
       ShapeLast:TKraftShape;

       ShapeCount:longint;

       Flags:TKraftRigidBodyFlags;

//     WorldAABB:TKraftAABB;

       WorldDisplacement:TKraftVector3;

//     WorldQuaternion:TKraftQuaternion;

       WorldTransform:TKraftMatrix4x4;

       Sweep:TKraftSweep;

       Gravity:TKraftVector3;

       UserData:pointer;

       TimeOfImpact:TKraftScalar;

       NextOnIslandBuildStack:TKraftRigidBody;
       NextStaticRigidBody:TKraftRigidBody;

       BodyInertiaTensor:TKraftMatrix3x3;
       BodyInverseInertiaTensor:TKraftMatrix3x3;

       WorldInertiaTensor:TKraftMatrix3x3;
       WorldInverseInertiaTensor:TKraftMatrix3x3;

       ForcedMass:TKraftScalar;

       Mass:TKraftScalar;
       InverseMass:TKraftScalar;

       LinearVelocity:TKraftVector3;
       AngularVelocity:TKraftVector3;

       MaximalLinearVelocity:TKraftScalar;
       MaximalAngularVelocity:TKraftScalar;

       LinearVelocityDamp:TKraftScalar;
       AngularVelocityDamp:TKraftScalar;
       AdditionalDamping:boolean;
       AdditionalDamp:TKraftScalar;
       LinearVelocityAdditionalDamp:TKraftScalar;
       AngularVelocityAdditionalDamp:TKraftScalar;
       LinearVelocityAdditionalDampThresholdSqr:TKraftScalar;
       AngularVelocityAdditionalDampThresholdSqr:TKraftScalar;

       Force:TKraftVector3;
       Torque:TKraftVector3;

       SleepTime:TKraftScalar;

       GravityScale:TKraftScalar;

       EnableGyroscopicForce:longbool;

       MaximalGyroscopicForce:TKraftScalar;

       CollisionGroups:TKraftRigidBodyCollisionGroups;

       CollideWithCollisionGroups:TKraftRigidBodyCollisionGroups;

       CountConstraints:longint;

       ConstraintEdgeFirst:PKraftConstraintEdge;
       ConstraintEdgeLast:PKraftConstraintEdge;

       ContactPairEdgeFirst:PKraftContactPairEdge;
       ContactPairEdgeLast:PKraftContactPairEdge;

       OnDamping:TKraftRigidBodyOnDamping;

       OnPreStep:TKraftRigidBodyOnStep;
       OnPostStep:TKraftRigidBodyOnStep;

       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;

       function SetRigidBodyType(ARigidBodyType:TKraftRigidBodyType):TKraftRigidBody;

       function IsStatic:boolean;
       function IsDynamic:boolean;
       function IsKinematic:boolean;

       procedure SynchronizeTransform;

       procedure SynchronizeTransformIncludingShapes;

       procedure StoreWorldTransform; virtual;

       procedure InterpolateWorldTransform(const Alpha:TKraftScalar); virtual;

       procedure Advance(Alpha:TKraftScalar);

       procedure UpdateWorldInertiaTensor;

       procedure Finish;

       procedure SynchronizeProxies;

       procedure Refilter;

       function CanCollideWith(OtherRigidBody:TKraftRigidBody):boolean;

       procedure SetToAwake;

       procedure SetToSleep;

       procedure SetWorldTransformation(const AWorldTransformation:TKraftMatrix4x4);

       procedure SetWorldPosition(const AWorldPosition:TKraftVector3);

       procedure SetOrientation(const AOrientation:TKraftMatrix3x3); overload;
       procedure SetOrientation(const x,y,z:TKraftScalar); overload;
       procedure AddOrientation(const x,y,z:TKraftScalar);

       procedure LimitVelocities;

       procedure ApplyImpulseAtPosition(const Point,Impulse:TKraftVector3);
       procedure ApplyImpulseAtRelativePosition(const RelativePosition,Impulse:TKraftVector3);

       procedure SetForceAtPosition(const AForce,APosition:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddForceAtPosition(const AForce,APosition:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetWorldForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddWorldForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetBodyForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddBodyForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetWorldTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddWorldTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetBodyTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddBodyTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetWorldAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddWorldAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetBodyAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddBodyAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetWorldAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddWorldAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       procedure SetBodyAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
       procedure AddBodyAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);

       property AngularMomentum:TKraftVector3 read GetAngularMomentum write SetAngularMomentum;
     end;

     PKraftSolverVelocity=^TKraftSolverVelocity;
     TKraftSolverVelocity=record
      LinearVelocity:TKraftVector3;
      AngularVelocity:TKraftVector3;
     end;

     TKraftSolverVelocities=array of TKraftSolverVelocity;

     PKraftSolverPosition=^TKraftSolverPosition;
     TKraftSolverPosition=record
      Position:TKraftVector3;
      Orientation:TKraftQuaternion;
     end;

     TKraftSolverPositions=array of TKraftSolverPosition;

     TKraftConstraintEdges=array[0..1] of TKraftConstraintEdge;

     TKraftConstraintRigidBodies=array[0..1] of TKraftRigidBody;

     TKraftConstraintLimitState=(kclsInactiveLimit,kclsAtLowerLimit,kclsAtUpperLimit,kclsEqualLimits);

     TKraftConstraintOnBreak=procedure(APhysics:TKraft;AConstraint:TKraftConstraint) of object;

     TKraftConstraint=class
      private

       Parent:TKraftConstraint;

       Children:array of TKraftConstraint;
       CountChildren:longint;

      public

       Physics:TKraft;

       Previous:TKraftConstraint;
       Next:TKraftConstraint;

       UserData:pointer;

       Flags:TKraftConstraintFlags;

       ConstraintEdges:TKraftConstraintEdges;

       RigidBodies:TKraftConstraintRigidBodies;

       BreakThresholdForce:TKraftScalar;

       BreakThresholdTorque:TKraftScalar;

       OnBreak:TKraftConstraintOnBreak;

       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;

       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); virtual;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); virtual;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; virtual;

       function GetAnchorA:TKraftVector3; virtual;
       function GetAnchorB:TKraftVector3; virtual;

       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; virtual;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; virtual;

     end;

     TKraftConstraintJoint=class(TKraftConstraint);

     // Constrains a body to a specified world position which can change over time.
     TKraftConstraintJointGrab=class(TKraftConstraintJoint)
      private
       IslandIndex:longint;
       InverseMass:TKraftScalar;
       SolverVelocity:PKraftSolverVelocity;
       SolverPosition:PKraftSolverPosition;
       WorldInverseInertiaTensor:TKraftMatrix3x3;
       RelativePosition:TKraftVector3;
       LocalCenter:TKraftVector3;
       LocalAnchor:TKraftVector3;
       mC:TKraftVector3;
       FrequencyHz:TKraftScalar;
       DampingRatio:TKraftScalar;
       AccumulatedImpulse:TKraftVector3;
       Beta:TKraftScalar;
       Gamma:TKraftScalar;
       Mass:TKraftScalar;
       EffectiveMass:TKraftMatrix3x3;
       WorldPoint:TKraftVector3;
       MaximalForce:TKraftScalar;
      public
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AWorldPoint:TKraftVector3;const AFrequencyHz:TKraftScalar=5.0;const ADampingRatio:TKraftScalar=0.7;const AMaximalForce:TKraftScalar=MAX_SCALAR;const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchor:TKraftVector3; virtual;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetWorldPoint:TKraftVector3; virtual;
       function GetMaximalForce:TKraftScalar; virtual;
       procedure SetWorldPoint(AWorldPoint:TKraftVector3); virtual;
       procedure SetMaximalForce(AMaximalForce:TKraftScalar); virtual;
     end;

     // Keeps body at some fixed distance to a world plane.
     TKraftConstraintJointWorldPlaneDistance=class(TKraftConstraintJoint)
      private
       IslandIndex:longint;
       InverseMass:TKraftScalar;
       SolverVelocity:PKraftSolverVelocity;
       SolverPosition:PKraftSolverPosition;
       WorldInverseInertiaTensor:TKraftMatrix3x3;
       RelativePosition:TKraftVector3;
       LocalCenter:TKraftVector3;
       LocalAnchor:TKraftVector3;
       mU:TKraftVector3;
       WorldPoint:TKraftVector3;
       WorldPlane:TKraftPlane;
       WorldDistance:TKraftScalar;
       FrequencyHz:TKraftScalar;
       DampingRatio:TKraftScalar;
       AccumulatedImpulse:TKraftScalar;
       Gamma:TKraftScalar;
       Bias:TKraftScalar;
       Mass:TKraftScalar;
       LimitBehavior:TKraftConstraintLimitBehavior;
       DoubleSidedWorldPlane:longbool;
       SoftConstraint:longbool;
       Skip:longbool;
      public
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const ALocalAnchorPoint:TKraftVector3;const AWorldPlane:TKraftPlane;const ADoubleSidedWorldPlane:boolean=true;const AWorldDistance:single=1.0;const ALimitBehavior:TKraftConstraintLimitBehavior=kclbLimitDistance;const AFrequencyHz:TKraftScalar=0.0;const ADampingRatio:TKraftScalar=0.0;const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchor:TKraftVector3; virtual;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetWorldPoint:TKraftVector3; virtual;
       function GetWorldPlane:TKraftPlane; virtual;
       procedure SetWorldPlane(const AWorldPlane:TKraftPlane); virtual;
       function GetWorldDistance:TKraftScalar; virtual;
       procedure SetWorldDistance(const AWorldDistance:TKraftScalar); virtual;
     end;

     // Keeps bodies at some fixed distance from each other.
     TKraftConstraintJointDistance=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       mU:TKraftVector3;
       AnchorDistanceLength:TKraftScalar;
       FrequencyHz:TKraftScalar;
       DampingRatio:TKraftScalar;
       AccumulatedImpulse:TKraftScalar;
       Gamma:TKraftScalar;
       Bias:TKraftScalar;
       Mass:TKraftScalar;
      public
       constructor Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const ALocalAnchorPointA,ALocalAnchorPointB:TKraftVector3;const AFrequencyHz:TKraftScalar=0.0;const ADampingRatio:TKraftScalar=0.0;const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
     end;

     // Restricts the maximum distance between two points.
     TKraftConstraintJointRope=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       MaximalLength:TKraftScalar;
       AccumulatedImpulse:TKraftScalar;
       mU:TKraftVector3;
       CurrentLength:TKraftScalar;
       Mass:TKraftScalar;
      public
       LimitState:TKraftConstraintLimitState;
       constructor Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const ALocalAnchorPointA,ALocalAnchorPointB:TKraftVector3;const AMaximalLength:TKraftScalar=1.0;const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
     end;

     // Connects two bodies to ground and to each other. As one body goes up, the other goes down.
     TKraftConstraintJointPulley=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       GroundAnchors:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       mU:array[0..1] of TKraftVector3;
       Lengths:array[0..1] of TKraftScalar;
       AccumulatedImpulse:TKraftScalar;
       Constant:TKraftScalar;
       Mass:TKraftScalar;
       Ratio:TKraftScalar;
      public
       constructor Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AWorldGroundAnchorA,AWorldGroundAnchorB,AWorldAnchorPointA,AWorldAnchorPointB:TKraftVector3;const ARatio:TKraftScalar=1.0;const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetCurrentLengthA:TKraftScalar;
       function GetCurrentLengthB:TKraftScalar;
     end;

     // Allows arbitrary rotation between two bodies. This joint has three degrees of freedom.
     TKraftConstraintJointBallSocket=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       AccumulatedImpulse:TKraftVector3;
       InverseMassMatrix:TKraftMatrix3x3;
      public
       constructor Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AWorldAnchorPoint:TKraftVector3;const ACollideConnected:boolean=false); reintroduce; overload;
       constructor Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const ALocalAnchorPointA,ALocalAnchorPointB:TKraftVector3;const ACollideConnected:boolean=false); reintroduce; overload;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
     end;

     // Forbids any translation or rotation between two bodies.
     TKraftConstraintJointFixed=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       AccumulatedImpulseTranslation:TKraftVector3;
       AccumulatedImpulseRotation:TKraftVector3;
       InverseMassMatrixTranslation:TKraftMatrix3x3;
       InverseMassMatrixRotation:TKraftMatrix3x3;
       InverseInitialOrientationDifference:TKraftQuaternion;
      public
       constructor Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AWorldAnchorPoint:TKraftVector3;const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
     end;

     // Allows arbitrary rotation between two bodies around a TKraftScalar axis. This joint has one degree of freedom.
     TKraftConstraintJointHinge=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       LocalAxes:array[0..1] of TKraftVector3;
       AccumulatedImpulseLowerLimit:TKraftScalar;
       AccumulatedImpulseUpperLimit:TKraftScalar;
       AccumulatedImpulseMotor:TKraftScalar;
       AccumulatedImpulseTranslation:TKraftVector3;
       AccumulatedImpulseRotation:TKraftVector2;
       B2CrossA1:TKraftVector3;
       C2CrossA1:TKraftVector3;
       A1:TKraftVector3;
       InverseMassMatrixTranslation:TKraftMatrix3x3;
       InverseMassMatrixRotation:TKraftMatrix2x2;
       InverseMassMatrixLimitMotor:TKraftScalar;
       InverseInitialOrientationDifference:TKraftQuaternion;
       LimitState:longbool;
       MotorState:longbool;
       LowerLimit:TKraftScalar;
       UpperLimit:TKraftScalar;
       IsLowerLimitViolated:longbool;
       IsUpperLimitViolated:longbool;
       MotorSpeed:TKraftScalar;
       MaximalMotorTorque:TKraftScalar;
       function ComputeCurrentHingeAngle(const OrientationA,OrientationB:TKraftQuaternion):TKraftScalar;
      public
       constructor Create(const APhysics:TKraft;
                          const ARigidBodyA,ARigidBodyB:TKraftRigidBody;
                          const AWorldAnchorPoint:TKraftVector3;
                          const AWorldRotationAxis:TKraftVector3;
                          const ALimitEnabled:boolean=false;
                          const AMotorEnabled:boolean=false;
                          const AMinimumAngleLimit:TKraftScalar=-1.0;
                          const AMaximumAngleLimit:TKraftScalar=1.0;
                          const AMotorSpeed:TKraftScalar=0.0;
                          const AMaximalMotorTorque:TKraftScalar=0.0;
                          const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function IsLimitEnabled:boolean; virtual;
       function IsMotorEnabled:boolean; virtual;
       function GetMinimumAngleLimit:TKraftScalar; virtual;
       function GetMaximumAngleLimit:TKraftScalar; virtual;
       function GetMotorSpeed:TKraftScalar; virtual;
       function GetMaximalMotorTorque:TKraftScalar; virtual;
       function GetMotorTorque(const DeltaTime:TKraftScalar):TKraftScalar; virtual;
       procedure ResetLimits; virtual;
       procedure EnableLimit(const ALimitEnabled:boolean); virtual;
       procedure EnableMotor(const AMotorEnabled:boolean); virtual;
       procedure SetMinimumAngleLimit(const AMinimumAngleLimit:TKraftScalar); virtual;
       procedure SetMaximumAngleLimit(const AMaximumAngleLimit:TKraftScalar); virtual;
       procedure SetMotorSpeed(const AMotorSpeed:TKraftScalar); virtual;
       procedure SetMaximalMotorTorque(const AMaximalMotorTorque:TKraftScalar); virtual;
     end;

     // Allows relative translation of the bodies along a TKraftScalar direction and no rotation
     TKraftConstraintJointSlider=class(TKraftConstraintJoint)
      private
       IslandIndices:array[0..1] of longint;
       InverseMasses:array[0..1] of TKraftScalar;
       SolverVelocities:array[0..1] of PKraftSolverVelocity;
       SolverPositions:array[0..1] of PKraftSolverPosition;
       WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
       RelativePositions:array[0..1] of TKraftVector3;
       LocalCenters:array[0..1] of TKraftVector3;
       LocalAnchors:array[0..1] of TKraftVector3;
       AccumulatedImpulseLowerLimit:TKraftScalar;
       AccumulatedImpulseUpperLimit:TKraftScalar;
       AccumulatedImpulseMotor:TKraftScalar;
       AccumulatedImpulseTranslation:TKraftVector2;
       AccumulatedImpulseRotation:TKraftVector3;
       SliderAxisBodyA:TKraftVector3;
       SliderAxisWorld:TKraftVector3;
       N1:TKraftVector3;
       N2:TKraftVector3;
       R2CrossN1:TKraftVector3;
       R2CrossN2:TKraftVector3;
       R2CrossSliderAxis:TKraftVector3;
       R1PlusUCrossN1:TKraftVector3;
       R1PlusUCrossN2:TKraftVector3;
       R1PlusUCrossSliderAxis:TKraftVector3;
       InverseMassMatrixTranslationConstraint:TKraftMatrix2x2;
       InverseMassMatrixRotationConstraint:TKraftMatrix3x3;
       InverseMassMatrixLimit:TKraftScalar;
       InverseMassMatrixMotor:TKraftScalar;
       InverseInitialOrientationDifference:TKraftQuaternion;
       LimitState:longbool;
       MotorState:longbool;
       LowerLimit:TKraftScalar;
       UpperLimit:TKraftScalar;
       IsLowerLimitViolated:longbool;
       IsUpperLimitViolated:longbool;
       MotorSpeed:TKraftScalar;
       MaximalMotorForce:TKraftScalar;
      public
       constructor Create(const APhysics:TKraft;
                          const ARigidBodyA,ARigidBodyB:TKraftRigidBody;
                          const AWorldAnchorPoint:TKraftVector3;
                          const AWorldSliderAxis:TKraftVector3;
                          const ALimitEnabled:boolean=false;
                          const AMotorEnabled:boolean=false;
                          const AMinimumTranslationLimit:TKraftScalar=-1.0;
                          const AMaximumTranslationLimit:TKraftScalar=1.0;
                          const AMotorSpeed:TKraftScalar=0.0;
                          const AMaximalMotorForce:TKraftScalar=0.0;
                          const ACollideConnected:boolean=false); reintroduce;
       destructor Destroy; override;
       procedure InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       procedure SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep); override;
       function SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean; override;
       function GetAnchorA:TKraftVector3; override;
       function GetAnchorB:TKraftVector3; override;
       function GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3; override;
       function IsLimitEnabled:boolean; virtual;
       function IsMotorEnabled:boolean; virtual;
       function GetMinimumTranslationLimit:TKraftScalar; virtual;
       function GetMaximumTranslationLimit:TKraftScalar; virtual;
       function GetMotorSpeed:TKraftScalar; virtual;
       function GetMaximalMotorForce:TKraftScalar; virtual;
       function GetMotorForce(const DeltaTime:TKraftScalar):TKraftScalar; virtual;
       function GetTranslation:TKraftScalar; virtual;
       procedure ResetLimits; virtual;
       procedure EnableLimit(const ALimitEnabled:boolean); virtual;
       procedure EnableMotor(const AMotorEnabled:boolean); virtual;
       procedure SetMinimumTranslationLimit(const AMinimumTranslationLimit:TKraftScalar); virtual;
       procedure SetMaximumTranslationLimit(const AMaximumTranslationLimit:TKraftScalar); virtual;
       procedure SetMotorSpeed(const AMotorSpeed:TKraftScalar); virtual;
       procedure SetMaximalMotorForce(const AMaximalMotorForce:TKraftScalar); virtual;
     end;

     PKraftSolverVelocityStateContactPoint=^TKraftSolverVelocityStateContactPoint;
     TKraftSolverVelocityStateContactPoint=record
      RelativePositions:array[0..1] of TKraftVector3; // Vectors from center of mass to contact position
	    Penetration:TKraftScalar; // Depth of penetration from collision
	    NormalImpulse:TKraftScalar; // Accumulated normal impulse
	    TangentImpulse:array[0..1] of TKraftScalar; // Accumulated friction impulse
	    Bias:TKraftScalar; // Restitution + baumgarte
      NormalMass:TKraftScalar; // Normal constraint mass
      TangentMass:array[0..1] of TKraftScalar; // Tangent constraint mass
     end;

     PKraftSolverVelocityState=^TKraftSolverVelocityState;
     TKraftSolverVelocityState=record
      Points:array[0..MAX_CONTACTS-1] of TKraftSolverVelocityStateContactPoint;
      Normal:TKraftVector3;
      Centers:array[0..1] of TKraftVector3;
      WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
      NormalMass:TKraftScalar;
      TangentMass:array[0..1] of TKraftScalar;
      InverseMasses:array[0..1] of TKraftScalar;
      Restitution:TKraftScalar;
      Friction:TKraftScalar;
      Indices:array[0..1] of longint;
      CountPoints:longint;
     end;

     TKraftSolverVelocityStates=array of TKraftSolverVelocityState;

     PKraftSolverPositionState=^TKraftSolverPositionState;
     TKraftSolverPositionState=record
      LocalPoints:array[0..MAX_CONTACTS-1] of TKraftVector3;
      LocalNormal:TKraftVector3;
      LocalCenters:array[0..1] of TKraftVector3;
      WorldInverseInertiaTensors:array[0..1] of TKraftMatrix3x3;
      InverseMasses:array[0..1] of TKraftScalar;
      Indices:array[0..1] of longint;
      CountPoints:longint;
     end;

     TKraftSolverPositionStates=array of TKraftSolverPositionState;

     TKraftSolver=class
      public

       Physics:TKraft;

       Island:TKraftIsland;

       Velocities:TKraftSolverVelocities;
       CountVelocities:longint;

       Positions:TKraftSolverPositions;
       CountPositions:longint;

       VelocityStates:TKraftSolverVelocityStates;
       CountVelocityStates:longint;

       PositionStates:TKraftSolverPositionStates;
       CountPositionStates:longint;

       CountContacts:longint;

       DeltaTime:TKraftScalar;

       DeltaTimeRatio:TKraftScalar;

       EnableFriction:longbool;

       constructor Create(const APhysics:TKraft;const AIsland:TKraftIsland);
       destructor Destroy; override;

       procedure Store;
       
       procedure Initialize(const TimeStep:TKraftTimeStep);

       procedure InitializeConstraints;

       procedure WarmStart;

       procedure SolveVelocityConstraints;

       function SolvePositionConstraints:boolean;

       function SolveTimeOfImpactConstraints(IndexA,IndexB:longint):boolean;

       procedure StoreImpulses;

     end;

     TKraftIsland=class
      public

       Physics:TKraft;

       IslandIndex:longint;

       RigidBodies:array of TKraftRigidBody;
       CountRigidBodies:longint;

       Constraints:array of TKraftConstraint;
       CountConstraints:longint;

       ContactPairs:TPKraftContactPairs;
       CountContactPairs:longint;

       StaticContactPairs:TPKraftContactPairs;
       CountStaticContactPairs:longint;

       Solver:TKraftSolver;

       constructor Create(const APhysics:TKraft;const AIndex:longint);
       destructor Destroy; override;
       procedure Clear;
       function AddRigidBody(RigidBody:TKraftRigidBody):longint;
       procedure AddConstraint(Constraint:TKraftConstraint);
       procedure AddContactPair(ContactPair:PKraftContactPair);
       procedure MergeContactPairs;
       procedure Solve(const TimeStep:TKraftTimeStep);
       procedure SolveTimeOfImpact(const TimeStep:TKraftTimeStep;const IndexA,IndexB:longint);
     end;

     TKraftJobManager=class;

     TKraftJobManagerOnProcessJob=procedure(const JobIndex,ThreadIndex:longint) of object;

     TKraftJobThread=class(TThread)
      protected
       procedure Execute; override;
      public
       Physics:TKraft;
       JobManager:TKraftJobManager;
       ThreadNumber:longint;
       Event:TEvent;
       DoneEvent:TEvent;
       constructor Create(const APhysics:TKraft;const AJobManager:TKraftJobManager;const AThreadNumber:longint);
       destructor Destroy; override;
     end;

     TKraftJobManager=class
      public
       Physics:TKraft;
       Threads:array of TKraftJobThread;
       CountThreads:longint;
       CountAliveThreads:longint;
       ThreadsTerminated:longbool;
       OnProcessJob:TKraftJobManagerOnProcessJob;
       CountRemainJobs:longint;
       constructor Create(const APhysics:TKraft);
       destructor Destroy; override;
       procedure WakeUp;
       procedure WaitFor;
       procedure ProcessJobs;
     end;

     TKraft=class
      private

       IsSolving:longbool;
       TriangleShapes:array of TKraftShape;

       JobTimeStep:TKraftTimeStep;

       procedure Integrate(var Position:TKraftVector3;var Orientation:TKraftQuaternion;const LinearVelocity,AngularVelocity:TKraftVector3;const DeltaTime:TKraftScalar);

       procedure BuildIslands;
       procedure ProcessSolveIslandJob(const JobIndex,ThreadIndex:longint);
       procedure SolveIslands(const TimeStep:TKraftTimeStep);

       function GetConservativeAdvancementTimeOfImpact(const ShapeA:TKraftShape;const SweepA:TKraftSweep;const ShapeB:TKraftShape;const ShapeBTriangleIndex:longint;const SweepB:TKraftSweep;const TimeStep:TKraftTimeStep;const ThreadIndex:longint;var Beta:TKraftScalar):boolean;

       function GetBilateralAdvancementTimeOfImpact(const ShapeA:TKraftShape;const SweepA:TKraftSweep;const ShapeB:TKraftShape;const ShapeBTriangleIndex:longint;const SweepB:TKraftSweep;const TimeStep:TKraftTimeStep;const ThreadIndex:longint;var Beta:TKraftScalar):boolean;

       function GetTimeOfImpact(const ShapeA:TKraftShape;const SweepA:TKraftSweep;const ShapeB:TKraftShape;const ShapeBTriangleIndex:longint;const SweepB:TKraftSweep;const TimeStep:TKraftTimeStep;const ThreadIndex:longint;var Beta:TKraftScalar):boolean;

       procedure Solve(const TimeStep:TKraftTimeStep);

       procedure SolveContinuousTimeOfImpactSubSteps(const TimeStep:TKraftTimeStep);

       procedure SolveContinuousMotionClamping(const TimeStep:TKraftTimeStep);

      public

       HighResolutionTimer:TKraftHighResolutionTimer;

       BroadPhaseTime:int64;
       MidPhaseTime:int64;
       NarrowPhaseTime:int64;
       SolverTime:int64;
       ContinuousTime:int64;
       TotalTime:int64;

       NewShapes:longbool;

       ConvexHullFirst:TKraftConvexHull;
       ConvexHullLast:TKraftConvexHull;

       MeshFirst:TKraftMesh;
       MeshLast:TKraftMesh;

       ConstraintFirst:TKraftConstraint;
       ConstraintLast:TKraftConstraint;

       CountRigidBodies:longint;
       RigidBodyIDCounter:uint64;

       RigidBodyFirst:TKraftRigidBody;
       RigidBodyLast:TKraftRigidBody;

       StaticRigidBodyCount:longint;

       StaticRigidBodyFirst:TKraftRigidBody;
       StaticRigidBodyLast:TKraftRigidBody;

       DynamicRigidBodyCount:longint;

       DynamicRigidBodyFirst:TKraftRigidBody;
       DynamicRigidBodyLast:TKraftRigidBody;

       KinematicRigidBodyCount:longint;

       KinematicRigidBodyFirst:TKraftRigidBody;
       KinematicRigidBodyLast:TKraftRigidBody;

       StaticAABBTree:TKraftDynamicAABBTree;
       SleepingAABBTree:TKraftDynamicAABBTree;
       DynamicAABBTree:TKraftDynamicAABBTree;
       KinematicAABBTree:TKraftDynamicAABBTree;

       Islands:array of TKraftIsland;
       CountIslands:longint;

       BroadPhase:TKraftBroadPhase;

       ContactManager:TKraftContactManager;

       WorldFrequency:TKraftScalar;

       WorldDeltaTime:TKraftScalar;

       WorldInverseDeltaTime:TKraftScalar;

       LastInverseDeltaTime:TKraftScalar;

       AllowSleep:longbool;

       AllowedPenetration:TKraftScalar;

       Gravity:TKraftVector3;

       MaximalLinearVelocity:TKraftScalar;
       LinearVelocityThreshold:TKraftScalar;

       MaximalAngularVelocity:TKraftScalar;
       AngularVelocityThreshold:TKraftScalar;

       SleepTimeThreshold:TKraftScalar;

       Baumgarte:TKraftScalar;

       TimeOfImpactBaumgarte:TKraftScalar;

       PenetrationSlop:TKraftScalar;

       LinearSlop:TKraftScalar;

       AngularSlop:TKraftScalar;

       MaximalLinearCorrection:TKraftScalar;

       MaximalAngularCorrection:TKraftScalar;

       WarmStarting:longbool;

       ContinuousMode:TKraftContinuousMode;

       ContinuousAgainstDynamics:longbool;

       TimeOfImpactAlgorithm:TKraftTimeOfImpactAlgorithm;

       MaximalSubSteps:longint;

       VelocityIterations:longint;

       PositionIterations:longint;

       TimeOfImpactIterations:longint;

       PerturbationIterations:longint;

       AlwaysPerturbating:longbool;

       EnableFriction:longbool;

       LinearVelocityRK4Integration:longbool;

       AngularVelocityRK4Integration:longbool;

       ContactBreakingThreshold:TKraftScalar;

       CountThreads:longint;

       JobManager:TKraftJobManager;

       constructor Create(const ACountThreads:longint=-1);
       destructor Destroy; override;

       procedure SetFrequency(const AFrequency:TKraftScalar);

       procedure StoreWorldTransforms;

       procedure InterpolateWorldTransforms(const Alpha:TKraftScalar);

       procedure Step(const ADeltaTime:TKraftScalar=0);

       function TestPoint(const Point:TKraftVector3):TKraftShape;

       function RayCast(const Origin,Direction:TKraftVector3;const MaxTime:TKraftScalar;var Shape:TKraftShape;var Time:TKraftScalar;var Point,Normal:TKraftVector3;const CollisionGroups:TKraftRigidBodyCollisionGroups=[low(TKraftRigidBodyCollisionGroup)..high(TKraftRigidBodyCollisionGroup)]):boolean;

       function PushSphere(var Center:TKraftVector3;const Radius:TKraftScalar;const CollisionGroups:TKraftRigidBodyCollisionGroups=[low(TKraftRigidBodyCollisionGroup)..high(TKraftRigidBodyCollisionGroup)];const TryIterations:longint=4):boolean;

       function GetDistance(const ShapeA,ShapeB:TKraftShape):TKraftScalar;

     end;

const Vector2Origin:TKraftVector2=(x:0.0;y:0.0);
      Vector2XAxis:TKraftVector2=(x:1.0;y:0.0);
      Vector2YAxis:TKraftVector2=(x:0.0;y:1.0);
      Vector2ZAxis:TKraftVector2=(x:0.0;y:0.0);

{$ifdef SIMD}
      Vector3Origin:TKraftVector3=(x:0.0;y:0.0;z:0.0;w:0.0);
      Vector3XAxis:TKraftVector3=(x:1.0;y:0.0;z:0.0;w:0.0);
      Vector3YAxis:TKraftVector3=(x:0.0;y:1.0;z:0.0;w:0.0);
      Vector3ZAxis:TKraftVector3=(x:0.0;y:0.0;z:1.0;w:0.0);
      Vector3All:TKraftVector3=(x:1.0;y:1.0;z:1.0;w:0.0);
{$else}
      Vector3Origin:TKraftVector3=(x:0.0;y:0.0;z:0.0);
      Vector3XAxis:TKraftVector3=(x:1.0;y:0.0;z:0.0);
      Vector3YAxis:TKraftVector3=(x:0.0;y:1.0;z:0.0);
      Vector3ZAxis:TKraftVector3=(x:0.0;y:0.0;z:1.0);
      Vector3All:TKraftVector3=(x:1.0;y:1.0;z:1.0);
{$endif}

      Vector4Origin:TKraftVector4=(x:0.0;y:0.0;z:0.0;w:1.0);
      Vector4XAxis:TKraftVector4=(x:1.0;y:0.0;z:0.0;w:1.0);
      Vector4YAxis:TKraftVector4=(x:0.0;y:1.0;z:0.0;w:1.0);
      Vector4ZAxis:TKraftVector4=(x:0.0;y:0.0;z:1.0;w:1.0);

      Matrix2x2Identity:TKraftMatrix2x2=((1.0,0.0),(0.0,1.0));
      Matrix2x2Null:TKraftMatrix2x2=((0.0,0.0),(0.0,0.0));

{$ifdef SIMD}
      Matrix3x3Identity:TKraftMatrix3x3=((1.0,0.0,0.0,0.0),(0.0,1.0,0.0,0.0),(0.0,0.0,1.0,0.0));
      Matrix3x3Null:TKraftMatrix3x3=((0.0,0.0,0.0,0.0),(0.0,0.0,0.0,0.0),(0.0,0.0,0.0,0.0));
{$else}
      Matrix3x3Identity:TKraftMatrix3x3=((1.0,0.0,0.0),(0.0,1.0,0.0),(0.0,0.0,1.0));
      Matrix3x3Null:TKraftMatrix3x3=((0.0,0.0,0.0),(0.0,0.0,0.0),(0.0,0.0,0.0));
{$endif}

      Matrix4x4Identity:TKraftMatrix4x4=((1.0,0.0,0,0.0),(0.0,1.0,0.0,0.0),(0.0,0.0,1.0,0.0),(0.0,0.0,0,1.0));
      Matrix4x4RightToLeftHanded:TKraftMatrix4x4=((1.0,0.0,0,0.0),(0.0,1.0,0.0,0.0),(0.0,0.0,-1.0,0.0),(0.0,0.0,0,1.0));
      Matrix4x4Flip:TKraftMatrix4x4=((0.0,0.0,-1.0,0.0),(-1.0,0.0,0,0.0),(0.0,1.0,0.0,0.0),(0.0,0.0,0,1.0));
      Matrix4x4InverseFlip:TKraftMatrix4x4=((0.0,-1.0,0.0,0.0),(0.0,0.0,1.0,0.0),(-1.0,0.0,0,0.0),(0.0,0.0,0,1.0));
      Matrix4x4FlipYZ:TKraftMatrix4x4=((1.0,0.0,0,0.0),(0.0,0.0,1.0,0.0),(0.0,-1.0,0.0,0.0),(0.0,0.0,0,1.0));
      Matrix4x4InverseFlipYZ:TKraftMatrix4x4=((1.0,0.0,0,0.0),(0.0,0.0,-1.0,0.0),(0.0,1.0,0.0,0.0),(0.0,0.0,0,1.0));
      Matrix4x4Null:TKraftMatrix4x4=((0.0,0.0,0,0.0),(0.0,0.0,0,0.0),(0.0,0.0,0,0.0),(0.0,0.0,0,0.0));
      Matrix4x4NormalizedSpace:TKraftMatrix4x4=((2.0,0.0,0,0.0),(0.0,2.0,0.0,0.0),(0.0,0.0,2.0,0.0),(-1.0,-1.0,-1.0,1.0));

      QuaternionIdentity:TKraftQuaternion=(x:0.0;y:0.0;z:0.0;w:1.0);

function Vector2(x,y:TKraftScalar):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector3(x,y,z:TKraftScalar):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3(const v:TKraftVector4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Matrix3x3(const m:TKraftMatrix4x4):TKraftMatrix3x3; overload; {$ifdef caninline}inline;{$endif}
function Plane(Normal:TKraftVector3;Distance:TKraftScalar):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
function Quaternion(w,x,y,z:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}

function Vector2Compare(const v1,v2:TKraftVector2):boolean; {$ifdef caninline}inline;{$endif}
function Vector2CompareEx(const v1,v2:TKraftVector2;const Threshold:TKraftScalar=EPSILON):boolean; {$ifdef caninline}inline;{$endif}
function Vector2Add(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector2Sub(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector2Avg(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector2ScalarMul(const v:TKraftVector2;s:TKraftScalar):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector2Dot(const v1,v2:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector2Neg(const v:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
procedure Vector2Scale(var v:TKraftVector2;s:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
procedure Vector2Scale(var v:TKraftVector2;sx,sy:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
function Vector2Mul(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector2Length(const v:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector2Dist(const v1,v2:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector2LengthSquared(const v:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector2Angle(const v1,v2,v3:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
procedure Vector2Normalize(var v:TKraftVector2); {$ifdef caninline}inline;{$endif}
function Vector2Norm(const v:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
procedure Vector2Rotate(var v:TKraftVector2;a:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
procedure Vector2Rotate(var v:TKraftVector2;const Center:TKraftVector2;a:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
procedure Vector2MatrixMul(var v:TKraftVector2;const m:TKraftMatrix2x2); {$ifdef caninline}inline;{$endif}
function Vector2TermMatrixMul(const v:TKraftVector2;const m:TKraftMatrix2x2):TKraftVector2; {$ifdef caninline}inline;{$endif}
function Vector2Lerp(const v1,v2:TKraftVector2;w:TKraftScalar):TKraftVector2; {$ifdef caninline}inline;{$endif}

{$ifdef SIMD}
function Vector3Flip(const v:TKraftVector3):TKraftVector3;
function Vector3Abs(const v:TKraftVector3):TKraftVector3;
function Vector3Compare(const v1,v2:TKraftVector3):boolean;
function Vector3CompareEx(const v1,v2:TKraftVector3;const Threshold:TKraftScalar=EPSILON):boolean;
procedure Vector3DirectAdd(var v1:TKraftVector3;const v2:TKraftVector3);
procedure Vector3DirectSub(var v1:TKraftVector3;const v2:TKraftVector3);
function Vector3Add(const v1,v2:TKraftVector3):TKraftVector3;
function Vector3Sub(const v1,v2:TKraftVector3):TKraftVector3;
function Vector3Avg(const v1,v2:TKraftVector3):TKraftVector3; overload;
function Vector3Avg(const v1,v2,v3:TKraftVector3):TKraftVector3; overload;
function Vector3Avg(const va:PKraftVector3s;Count:longint):TKraftVector3; overload;
function Vector3ScalarMul(const v:TKraftVector3;const s:TKraftScalar):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3Dot(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3Cos(const v1,v2:TKraftVector3):TKraftScalar;
function Vector3GetOneUnitOrthogonalVector(const v:TKraftVector3):TKraftVector3;
function Vector3Cross(const v1,v2:TKraftVector3):TKraftVector3;
function Vector3Neg(const v:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
procedure Vector3Scale(var v:TKraftVector3;const sx,sy,sz:TKraftScalar); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
procedure Vector3Scale(var v:TKraftVector3;const s:TKraftScalar); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3Mul(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3Length(const v:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3Dist(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3LengthSquared(const v:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3DistSquared(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3Angle(const v1,v2,v3:TKraftVector3):TKraftScalar;
function Vector3LengthNormalize(var v:TKraftVector3):TKraftScalar;
procedure Vector3Normalize(var v:TKraftVector3);
procedure Vector3NormalizeEx(var v:TKraftVector3);
function Vector3SafeNorm(const v:TKraftVector3):TKraftVector3;
function Vector3Norm(const v:TKraftVector3):TKraftVector3;
function Vector3NormEx(const v:TKraftVector3):TKraftVector3; 
procedure Vector3RotateX(var v:TKraftVector3;a:TKraftScalar);
procedure Vector3RotateY(var v:TKraftVector3;a:TKraftScalar);
procedure Vector3RotateZ(var v:TKraftVector3;a:TKraftScalar);
procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix3x3); overload;
procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
procedure Vector3MatrixMulBasis(var v:TKraftVector3;const m:TKraftMatrix4x4); overload;
procedure Vector3MatrixMulInverted(var v:TKraftVector3;const m:TKraftMatrix4x4); overload;
function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload;
function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3TermMatrixMulInverse(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload;
function Vector3TermMatrixMulInverted(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload;
function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
function Vector3TermMatrixMulTransposedBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
function Vector3TermMatrixMulBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
function Vector3TermMatrixMulHomogen(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3;
function Vector3Lerp(const v1,v2:TKraftVector3;w:TKraftScalar):TKraftVector3;
function Vector3Perpendicular(v:TKraftVector3):TKraftVector3;
function Vector3TermQuaternionRotate(const v:TKraftVector3;const q:TKraftQuaternion):TKraftVector3;
function Vector3ProjectToBounds(const v:TKraftVector3;const MinVector,MaxVector:TKraftVector3):TKraftScalar;
{$else}
function Vector3Flip(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Abs(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Compare(const v1,v2:TKraftVector3):boolean; {$ifdef caninline}inline;{$endif}
function Vector3CompareEx(const v1,v2:TKraftVector3;const Threshold:TKraftScalar=EPSILON):boolean; {$ifdef caninline}inline;{$endif}
function Vector3DirectAdd(var v1:TKraftVector3;const v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3DirectSub(var v1:TKraftVector3;const v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Add(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Sub(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Avg(const v1,v2:TKraftVector3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3Avg(const v1,v2,v3:TKraftVector3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3Avg(const va:PKraftVector3s;Count:longint):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3ScalarMul(const v:TKraftVector3;const s:TKraftScalar):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Dot(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3Cos(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3GetOneUnitOrthogonalVector(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Cross(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Neg(const v:TKraftVector3):TKraftVector3;  {$ifdef caninline}inline;{$endif}
procedure Vector3Scale(var v:TKraftVector3;const sx,sy,sz:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
procedure Vector3Scale(var v:TKraftVector3;const s:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
function Vector3Mul(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Length(const v:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3Dist(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3LengthSquared(const v:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3DistSquared(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3Angle(const v1,v2,v3:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Vector3LengthNormalize(var v:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
procedure Vector3Normalize(var v:TKraftVector3); {$ifdef caninline}inline;{$endif}
procedure Vector3NormalizeEx(var v:TKraftVector3); {$ifdef caninline}inline;{$endif}
function Vector3SafeNorm(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Norm(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3NormEx(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
procedure Vector3RotateX(var v:TKraftVector3;a:TKraftScalar); {$ifdef caninline}inline;{$endif}
procedure Vector3RotateY(var v:TKraftVector3;a:TKraftScalar); {$ifdef caninline}inline;{$endif}
procedure Vector3RotateZ(var v:TKraftVector3;a:TKraftScalar); {$ifdef caninline}inline;{$endif}
procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix3x3); overload; {$ifdef caninline}inline;{$endif}
procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
procedure Vector3MatrixMulBasis(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef caninline}inline;{$endif}
procedure Vector3MatrixMulInverted(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef CPU386ASMForSinglePrecision}assembler;{$endif}
function Vector3TermMatrixMulInverse(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMulInverted(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMulTransposedBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMulBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
function Vector3TermMatrixMulHomogen(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Lerp(const v1,v2:TKraftVector3;w:TKraftScalar):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3Perpendicular(v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3TermQuaternionRotate(const v:TKraftVector3;const q:TKraftQuaternion):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Vector3ProjectToBounds(const v:TKraftVector3;const MinVector,MaxVector:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
{$endif}

function Vector4Compare(const v1,v2:TKraftVector4):boolean;
function Vector4CompareEx(const v1,v2:TKraftVector4;const Threshold:TKraftScalar=EPSILON):boolean;
function Vector4Add(const v1,v2:TKraftVector4):TKraftVector4;
function Vector4Sub(const v1,v2:TKraftVector4):TKraftVector4;
function Vector4ScalarMul(const v:TKraftVector4;s:TKraftScalar):TKraftVector4;
function Vector4Dot(const v1,v2:TKraftVector4):TKraftScalar;
function Vector4Cross(const v1,v2:TKraftVector4):TKraftVector4;
function Vector4Neg(const v:TKraftVector4):TKraftVector4;
procedure Vector4Scale(var v:TKraftVector4;sx,sy,sz:TKraftScalar); overload;
procedure Vector4Scale(var v:TKraftVector4;s:TKraftScalar); overload;
function Vector4Mul(const v1,v2:TKraftVector4):TKraftVector4;
function Vector4Length(const v:TKraftVector4):TKraftScalar;
function Vector4Dist(const v1,v2:TKraftVector4):TKraftScalar;
function Vector4LengthSquared(const v:TKraftVector4):TKraftScalar;
function Vector4DistSquared(const v1,v2:TKraftVector4):TKraftScalar;
function Vector4Angle(const v1,v2,v3:TKraftVector4):TKraftScalar;
procedure Vector4Normalize(var v:TKraftVector4);
function Vector4Norm(const v:TKraftVector4):TKraftVector4;
procedure Vector4RotateX(var v:TKraftVector4;a:TKraftScalar);
procedure Vector4RotateY(var v:TKraftVector4;a:TKraftScalar);
procedure Vector4RotateZ(var v:TKraftVector4;a:TKraftScalar);
procedure Vector4MatrixMul(var v:TKraftVector4;const m:TKraftMatrix4x4); {$ifdef CPU386ASMForSinglePrecision}register;{$endif}
function Vector4TermMatrixMul(const v:TKraftVector4;const m:TKraftMatrix4x4):TKraftVector4; {$ifdef CPU386ASMForSinglePrecision}register;{$endif}
function Vector4TermMatrixMulHomogen(const v:TKraftVector4;const m:TKraftMatrix4x4):TKraftVector4;
procedure Vector4Rotate(var v:TKraftVector4;const Axis:TKraftVector4;a:TKraftScalar);
function Vector4Lerp(const v1,v2:TKraftVector4;w:TKraftScalar):TKraftVector4;

function Matrix2x2Inverse(var mr:TKraftMatrix2x2;const ma:TKraftMatrix2x2):boolean;
function Matrix2x2TermInverse(const m:TKraftMatrix2x2):TKraftMatrix2x2;

function Matrix3x3RotateX(Angle:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
function Matrix3x3RotateY(Angle:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
function Matrix3x3RotateZ(Angle:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
function Matrix3x3Rotate(Angle:TKraftScalar;Axis:TKraftVector3):TKraftMatrix3x3; overload;
function Matrix3x3Scale(sx,sy,sz:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
procedure Matrix3x3Add(var m1:TKraftMatrix3x3;const m2:TKraftMatrix3x3); {$ifdef caninline}inline;{$endif}
procedure Matrix3x3Sub(var m1:TKraftMatrix3x3;const m2:TKraftMatrix3x3); {$ifdef caninline}inline;{$endif}
procedure Matrix3x3Mul(var m1:TKraftMatrix3x3;const m2:TKraftMatrix3x3);
function Matrix3x3TermAdd(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
function Matrix3x3TermSub(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
function Matrix3x3TermMul(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3;
function Matrix3x3TermMulTranspose(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3;
procedure Matrix3x3ScalarMul(var m:TKraftMatrix3x3;s:TKraftScalar); {$ifdef caninline}inline;{$endif}
function Matrix3x3TermScalarMul(const m:TKraftMatrix3x3;s:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
procedure Matrix3x3Transpose(var m:TKraftMatrix3x3); {$ifdef caninline}inline;{$endif}
function Matrix3x3TermTranspose(const m:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
function Matrix3x3Determinant(const m:TKraftMatrix3x3):TKraftScalar; {$ifdef caninline}inline;{$endif}
function Matrix3x3EulerAngles(const m:TKraftMatrix3x3):TKraftVector3;
procedure Matrix3x3SetColumn(var m:TKraftMatrix3x3;const c:longint;const v:TKraftVector3); {$ifdef caninline}inline;{$endif}
function Matrix3x3GetColumn(const m:TKraftMatrix3x3;const c:longint):TKraftVector3; {$ifdef caninline}inline;{$endif}
procedure Matrix3x3SetRow(var m:TKraftMatrix3x3;const r:longint;const v:TKraftVector3); {$ifdef caninline}inline;{$endif}
function Matrix3x3GetRow(const m:TKraftMatrix3x3;const r:longint):TKraftVector3; {$ifdef caninline}inline;{$endif}
function Matrix3x3Compare(const m1,m2:TKraftMatrix3x3):boolean;
function Matrix3x3Inverse(var mr:TKraftMatrix3x3;const ma:TKraftMatrix3x3):boolean;
function Matrix3x3TermInverse(const m:TKraftMatrix3x3):TKraftMatrix3x3;
procedure Matrix3x3OrthoNormalize(var m:TKraftMatrix3x3);
function Matrix3x3Slerp(const a,b:TKraftMatrix3x3;x:TKraftScalar):TKraftMatrix3x3;
function Matrix3x3FromToRotation(const FromDirection,ToDirection:TKraftVector3):TKraftMatrix3x3;
function Matrix3x3Construct(const Forwards,Up:TKraftVector3):TKraftMatrix3x3;
function Matrix3x3OuterProduct(const u,v:TKraftVector3):TKraftMatrix3x3;

function Matrix4x4Set(m:TKraftMatrix3x3):TKraftMatrix4x4;
function Matrix4x4Rotation(m:TKraftMatrix4x4):TKraftMatrix4x4;
function Matrix4x4RotateX(Angle:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4RotateY(Angle:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4RotateZ(Angle:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4Rotate(Angle:TKraftScalar;Axis:TKraftVector3):TKraftMatrix4x4; overload;
function Matrix4x4Translate(x,y,z:TKraftScalar):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
function Matrix4x4Translate(const v:TKraftVector3):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
function Matrix4x4Translate(const v:TKraftVector4):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
procedure Matrix4x4Translate(var m:TKraftMatrix4x4;const v:TKraftVector3); overload; {$ifdef caninline}inline;{$endif}
procedure Matrix4x4Translate(var m:TKraftMatrix4x4;const v:TKraftVector4); overload; {$ifdef caninline}inline;{$endif}
function Matrix4x4Scale(sx,sy,sz:TKraftScalar):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
function Matrix4x4Scale(const s:TKraftVector3):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
procedure Matrix4x4Add(var m1:TKraftMatrix4x4;const m2:TKraftMatrix4x4); {$ifdef caninline}inline;{$endif}
procedure Matrix4x4Sub(var m1:TKraftMatrix4x4;const m2:TKraftMatrix4x4); {$ifdef caninline}inline;{$endif}
procedure Matrix4x4Mul(var m1:TKraftMatrix4x4;const m2:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}register;{$endif}
procedure Matrix4x4Mul(var mr:TKraftMatrix4x4;const m1,m2:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}register;{$endif}
function Matrix4x4TermAdd(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
function Matrix4x4TermSub(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
function Matrix4x4TermMul(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef CPU386ASMForSinglePrecision}register;{$endif}
function Matrix4x4TermMulInverted(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
function Matrix4x4TermMulSimpleInverted(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
function Matrix4x4TermMulTranspose(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4;
function Matrix4x4Lerp(const a,b:TKraftMatrix4x4;x:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4Slerp(const a,b:TKraftMatrix4x4;x:TKraftScalar):TKraftMatrix4x4;
procedure Matrix4x4ScalarMul(var m:TKraftMatrix4x4;s:TKraftScalar); {$ifdef caninline}inline;{$endif}
procedure Matrix4x4Transpose(var m:TKraftMatrix4x4);
function Matrix4x4TermTranspose(const m:TKraftMatrix4x4):TKraftMatrix4x4;
function Matrix4x4Determinant(const m:TKraftMatrix4x4):TKraftScalar;
procedure Matrix4x4SetColumn(var m:TKraftMatrix4x4;const c:longint;const v:TKraftVector4); {$ifdef caninline}inline;{$endif}
function Matrix4x4GetColumn(const m:TKraftMatrix4x4;const c:longint):TKraftVector4; {$ifdef caninline}inline;{$endif}
procedure Matrix4x4SetRow(var m:TKraftMatrix4x4;const r:longint;const v:TKraftVector4); {$ifdef caninline}inline;{$endif}
function Matrix4x4GetRow(const m:TKraftMatrix4x4;const r:longint):TKraftVector4; {$ifdef caninline}inline;{$endif}
function Matrix4x4Compare(const m1,m2:TKraftMatrix4x4):boolean;
procedure Matrix4x4Reflect(var mr:TKraftMatrix4x4;Plane:TKraftPlane);
function Matrix4x4TermReflect(Plane:TKraftPlane):TKraftMatrix4x4;
function Matrix4x4SimpleInverse(var mr:TKraftMatrix4x4;const ma:TKraftMatrix4x4):boolean; {$ifdef caninline}inline;{$endif}
function Matrix4x4TermSimpleInverse(const ma:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
function Matrix4x4Inverse(var mr:TKraftMatrix4x4;const ma:TKraftMatrix4x4):boolean;
function Matrix4x4TermInverse(const ma:TKraftMatrix4x4):TKraftMatrix4x4;
function Matrix4x4InverseOld(var mr:TKraftMatrix4x4;const ma:TKraftMatrix4x4):boolean;
function Matrix4x4TermInverseOld(const ma:TKraftMatrix4x4):TKraftMatrix4x4;
function Matrix4x4GetSubMatrix3x3(const m:TKraftMatrix4x4;i,j:longint):TKraftMatrix3x3;
function Matrix4x4Frustum(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4Ortho(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4OrthoLH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4OrthoRH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4OrthoOffCenterLH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4OrthoOffCenterRH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4Perspective(fovy,Aspect,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
function Matrix4x4LookAt(const Eye,Center,Up:TKraftVector3):TKraftMatrix4x4;
function Matrix4x4Fill(const Eye,RightVector,UpVector,ForwardVector:TKraftVector3):TKraftMatrix4x4;
function Matrix4x4ConstructX(const xAxis:TKraftVector3):TKraftMatrix4x4;
function Matrix4x4ConstructY(const yAxis:TKraftVector3):TKraftMatrix4x4;
function Matrix4x4ConstructZ(const zAxis:TKraftVector3):TKraftMatrix4x4;
function Matrix4x4ProjectionMatrixClip(const ProjectionMatrix:TKraftMatrix4x4;const ClipPlane:TKraftPlane):TKraftMatrix4x4;

procedure PlaneNormalize(var Plane:TKraftPlane); {$ifdef caninline}inline;{$endif}
function PlaneMatrixMul(const Plane:TKraftPlane;const Matrix:TKraftMatrix4x4):TKraftPlane;
function PlaneTransform(const Plane:TKraftPlane;const Matrix:TKraftMatrix4x4):TKraftPlane; overload;
function PlaneTransform(const Plane:TKraftPlane;const Matrix,NormalMatrix:TKraftMatrix4x4):TKraftPlane; overload;
function PlaneFastTransform(const Plane:TKraftPlane;const Matrix:TKraftMatrix4x4):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
function PlaneVectorDistance(const Plane:TKraftPlane;const Point:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
function PlaneVectorDistance(const Plane:TKraftPlane;const Point:TKraftVector4):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
function PlaneFromPoints(const p1,p2,p3:TKraftVector3):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
function PlaneFromPoints(const p1,p2,p3:TKraftVector4):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}

function QuaternionNormal(const AQuaternion:TKraftQuaternion):TKraftScalar;
function QuaternionLengthSquared(const AQuaternion:TKraftQuaternion):TKraftScalar;
procedure QuaternionNormalize(var AQuaternion:TKraftQuaternion);
function QuaternionTermNormalize(const AQuaternion:TKraftQuaternion):TKraftQuaternion;
function QuaternionNeg(const AQuaternion:TKraftQuaternion):TKraftQuaternion;
function QuaternionConjugate(const AQuaternion:TKraftQuaternion):TKraftQuaternion;
function QuaternionInverse(const AQuaternion:TKraftQuaternion):TKraftQuaternion;
function QuaternionAdd(const q1,q2:TKraftQuaternion):TKraftQuaternion;
function QuaternionSub(const q1,q2:TKraftQuaternion):TKraftQuaternion;
function QuaternionScalarMul(const q:TKraftQuaternion;const s:TKraftScalar):TKraftQuaternion;
function QuaternionMul(const q1,q2:TKraftQuaternion):TKraftQuaternion; 
function QuaternionRotateAroundAxis(const q1,q2:TKraftQuaternion):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
function QuaternionFromAxisAngle(const Axis:TKraftVector3;Angle:TKraftScalar):TKraftQuaternion; overload; {$ifdef caninline}inline;{$endif}
function QuaternionFromSpherical(const Latitude,Longitude:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
procedure QuaternionToSpherical(const q:TKraftQuaternion;var Latitude,Longitude:TKraftScalar);
function QuaternionFromAngles(const Pitch,Yaw,Roll:TKraftScalar):TKraftQuaternion; overload; {$ifdef caninline}inline;{$endif}
function QuaternionFromAngles(const Angles:TKraftAngles):TKraftQuaternion; overload; {$ifdef caninline}inline;{$endif}
function QuaternionFromMatrix3x3(const AMatrix:TKraftMatrix3x3):TKraftQuaternion;
function QuaternionToMatrix3x3(AQuaternion:TKraftQuaternion):TKraftMatrix3x3;
function QuaternionFromTangentSpaceMatrix3x3(AMatrix:TKraftMatrix3x3):TKraftQuaternion;
function QuaternionToTangentSpaceMatrix3x3(AQuaternion:TKraftQuaternion):TKraftMatrix3x3;
function QuaternionFromMatrix4x4(const AMatrix:TKraftMatrix4x4):TKraftQuaternion;
function QuaternionToMatrix4x4(AQuaternion:TKraftQuaternion):TKraftMatrix4x4;
function QuaternionToEuler(const AQuaternion:TKraftQuaternion):TKraftVector3; {$ifdef caninline}inline;{$endif}
procedure QuaternionToAxisAngle(AQuaternion:TKraftQuaternion;var Axis:TKraftVector3;var Angle:TKraftScalar); {$ifdef caninline}inline;{$endif}
function QuaternionGenerator(AQuaternion:TKraftQuaternion):TKraftVector3; {$ifdef caninline}inline;{$endif}
function QuaternionLerp(const q1,q2:TKraftQuaternion;const t:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
function QuaternionNlerp(const q1,q2:TKraftQuaternion;const t:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
function QuaternionSlerp(const q1,q2:TKraftQuaternion;const t:TKraftScalar):TKraftQuaternion;
function QuaternionIntegrate(const q:TKraftQuaternion;const Omega:TKraftVector3;const DeltaTime:TKraftScalar):TKraftQuaternion;
function QuaternionSpin(const q:TKraftQuaternion;const Omega:TKraftVector3;const DeltaTime:TKraftScalar):TKraftQuaternion; overload;
procedure QuaternionDirectSpin(var q:TKraftQuaternion;const Omega:TKraftVector3;const DeltaTime:TKraftScalar); overload;
function QuaternionFromToRotation(const FromDirection,ToDirection:TKraftVector3):TKraftQuaternion; {$ifdef caninline}inline;{$endif}

implementation

const daabbtNULLNODE=-1;

      AABB_EXTENSION=0.1;

      AABB_MULTIPLIER=2.0;

      AABB_MAX_EXPANSION=128.0;

      AABBExtensionVector:TKraftVector3=(x:AABB_EXTENSION;y:AABB_EXTENSION;z:AABB_EXTENSION);

      pi2=pi*2.0;

{$ifdef cpu386}
      MMXExt:boolean=false;
      SSEExt:boolean=false;
      SSE2Ext:boolean=false;
      SSE3Ext:boolean=false;
{$endif}

{$ifdef fpc}
 {$undef OldDelphi}
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=23.0}
   {$undef OldDelphi}
type qword=uint64;
     ptruint=NativeUInt;
     ptrint=NativeInt;
  {$else}
   {$define OldDelphi}
  {$ifend}
 {$else}
  {$define OldDelphi}
 {$endif}
{$endif}
{$ifdef OldDelphi}
type qword=int64;
{$ifdef cpu64}
     ptruint=qword;
     ptrint=int64;
{$else}
     ptruint=longword;
     ptrint=longint;
{$endif}
{$endif}

type TUInt128=packed record
{$ifdef BIG_ENDIAN}
      case byte of
       0:(
        Hi,Lo:qword;
       );
       1:(
        Q3,Q2,Q1,Q0:longword;
       );
{$else}
      case byte of
       0:(
        Lo,Hi:qword;
       );
       1:(
        Q0,Q1,Q2,Q3:longword;
       );
{$endif}
     end;

function AddWithCarry(const a,b:longword;var Carry:longword):longword; {$ifdef caninline}inline;{$endif}
var r:qword;
begin
 r:=qword(a)+qword(b)+qword(Carry);
 Carry:=(r shr 32) and 1;
 result:=r and $ffffffff;
end;

function MultiplyWithCarry(const a,b:longword;var Carry:longword):longword; {$ifdef caninline}inline;{$endif}
var r:qword;
begin
 r:=(qword(a)*qword(b))+qword(Carry);
 Carry:=r shr 32;
 result:=r and $ffffffff;
end;

function DivideWithRemainder(const a,b:longword;var Remainder:longword):longword; {$ifdef caninline}inline;{$endif}
var r:qword;
begin
 r:=(qword(Remainder) shl 32) or a;
 Remainder:=r mod b;
 result:=r div b;
end;

procedure UInt64ToUInt128(var Dest:TUInt128;const x:qword); {$ifdef caninline}inline;{$endif}
begin
 Dest.Hi:=0;
 Dest.Lo:=x;
end;

procedure UInt128Add(var Dest:TUInt128;const x,y:TUInt128); {$ifdef caninline}inline;{$endif}
var a,b,c,d:qword;
begin
 a:=x.Hi shr 32;
 b:=x.Hi and $ffffffff;
 c:=x.Lo shr 32;
 d:=x.Lo and $ffffffff;
 inc(d,y.Lo and $ffffffff);
 inc(c,(y.Lo shr 32)+(d shr 32));
 inc(b,(y.Hi and $ffffffff)+(c shr 32));
 inc(a,(y.Hi shr 32)+(b shr 32));
 Dest.Hi:=((a and $ffffffff) shl 32) or (b and $ffffffff);
 Dest.Lo:=((c and $ffffffff) shl 32) or (d and $ffffffff);
end;

procedure UInt128Mul(var Dest:TUInt128;const x,y:TUInt128); {$ifdef caninline}inline;{$endif}
var c,xw,yw,dw:array[0..15] of longword;
    i,j,k:longint;
    v:longword;
begin
 for i:=0 to 15 do begin
  c[i]:=0;
 end;
 xw[7]:=(x.Lo shr 0) and $ffff;
 xw[6]:=(x.Lo shr 16) and $ffff;
 xw[5]:=(x.Lo shr 32) and $ffff;
 xw[4]:=(x.Lo shr 48) and $ffff;
 xw[3]:=(x.Hi shr 0) and $ffff;
 xw[2]:=(x.Hi shr 16) and $ffff;
 xw[1]:=(x.Hi shr 32) and $ffff;
 xw[0]:=(x.Hi shr 48) and $ffff;
 yw[7]:=(y.Lo shr 0) and $ffff;
 yw[6]:=(y.Lo shr 16) and $ffff;
 yw[5]:=(y.Lo shr 32) and $ffff;
 yw[4]:=(y.Lo shr 48) and $ffff;
 yw[3]:=(y.Hi shr 0) and $ffff;
 yw[2]:=(y.Hi shr 16) and $ffff;
 yw[1]:=(y.Hi shr 32) and $ffff;
 yw[0]:=(y.Hi shr 48) and $ffff;
 for i:=0 to 7 do begin
  for j:=0 to 7 do begin
   v:=xw[i]*yw[j];
   k:=i+j;
   inc(c[k],v shr 16);
   inc(c[k+1],v and $ffff);
  end;
 end;
 for i:=15 downto 1 do begin
  inc(c[i-1],c[i] shr 16);
  c[i]:=c[i] and $ffff;
 end;
 for i:=0 to 7 do begin
  dw[i]:=c[8+i];
 end;
 Dest.Hi:=(qword(dw[0] and $ffff) shl 48) or (qword(dw[1] and $ffff) shl 32) or (qword(dw[2] and $ffff) shl 16) or (qword(dw[3] and $ffff) shl 0);
 Dest.Lo:=(qword(dw[4] and $ffff) shl 48) or (qword(dw[5] and $ffff) shl 32) or (qword(dw[6] and $ffff) shl 16) or (qword(dw[7] and $ffff) shl 0);
end;

procedure UInt128Div64(var Dest:TUInt128;const Dividend:TUInt128;Divisor:qword); {$ifdef caninline}inline;{$endif}
var Quotient:TUInt128;
    Remainder:qword;
    Bit:longint;
begin
 Quotient:=Dividend;
 Remainder:=0;
 for Bit:=1 to 128 do begin
  Remainder:=(Remainder shl 1) or (ord((Quotient.Hi and $8000000000000000)<>0) and 1);
  Quotient.Hi:=(Quotient.Hi shl 1) or (Quotient.Lo shr 63);
  Quotient.Lo:=Quotient.Lo shl 1;
  if (longword(Remainder shr 32)>longword(Divisor shr 32)) or
     ((longword(Remainder shr 32)=longword(Divisor shr 32)) and (longword(Remainder and $ffffffff)>=longword(Divisor and $ffffffff))) then begin
   dec(Remainder,Divisor);
   Quotient.Lo:=Quotient.Lo or 1;
  end;
 end;
 Dest:=Quotient;
end;

procedure UInt128Mul64(var Dest:TUInt128;u,v:qword); {$ifdef caninline}inline;{$endif}
var u0,u1,v0,v1,k,t,w0,w1,w2:qword;
begin
 u1:=u shr 32;
 u0:=u and qword($ffffffff);
 v1:=v shr 32;
 v0:=v and qword($ffffffff);
 t:=u0*v0;
 w0:=t and qword($ffffffff);
 k:=t shr 32;
 t:=(u1*v0)+k;
 w1:=t and qword($ffffffff);
 w2:=t shr 32;
 t:=(u0*v1)+w1;
 k:=t shr 32;
 Dest.Lo:=(t shl 32)+w0;
 Dest.Hi:=((u1*v1)+w2)+k;
end;

function RoundUpToPowerOfTwo(x:longword):longword; {$ifdef caninline}inline;{$endif}
begin
 dec(x);
 x:=x or (x shr 1);
 x:=x or (x shr 2);
 x:=x or (x shr 4);
 x:=x or (x shr 8);
 x:=x or (x shr 16);
 result:=x+1;
end;

function SIMDGetFlags:longword; {$ifdef cpu386}assembler;
asm
 stmxcsr dword ptr result
end;
{$else}
begin
 result:=0;
end;
{$endif}

procedure SIMDSetFlags(const Flags:longword); {$ifdef cpu386}register; assembler;
var Temp:longword;
asm
 mov dword ptr Temp,eax
 ldmxcsr dword ptr Temp
end;
{$else}
begin
end;
{$endif}

procedure SIMDSetOurFlags;
{$ifdef cpu386}
// Flush to Zero=Bit 15
// Underflow exception mask=Bit 11
// Denormals are zeros=Bit 6
// Denormal exception mask=Bit 8
// $8840(ftz+uem+daz+dem) and $8940(ftz+uem+daz)
const DenormalsAreZero=1 shl 6;
      InvalidOperationExceptionMask=1 shl 7;
      DenormalExceptionMask=1 shl 8;
      DivodeByZeroExceptionMask=1 shl 9;
      OverflowExceptionMask=1 shl 10;
      UnderflowExceptionMask=1 shl 11;
      PrecisionMask=1 shl 12;
      FlushToZero=1 shl 15;
      SIMDFlags=InvalidOperationExceptionMask or DenormalExceptionMask or DivodeByZeroExceptionMask or OverflowExceptionMask or UnderflowExceptionMask or PrecisionMask or FlushToZero or DenormalsAreZero;
      RoundToNearest=longword(longword($ffffffff) and not ((1 shl 13) or (1 shl 14)));
var SIMDCtrl:longword;
begin
 if SSEExt then begin
  asm
   push eax
   stmxcsr dword ptr SIMDCtrl
   mov eax,dword ptr SIMDCtrl
   or eax,SIMDFlags
   and eax,RoundToNearest
   mov dword ptr SIMDCtrl,eax
   ldmxcsr dword ptr SIMDCtrl
   pop eax
  end;
 end;
end;
{$else}
begin
end;
{$endif}

procedure CheckCPU;
{$ifdef cpu386}
var Features,FeaturesExt:longword;
{$endif}
begin
{$ifdef cpu386}
 Features:=0;
 FeaturesExt:=0;
 asm
  pushad

  // Check for CPUID opcode
  pushfd
  pop eax
  mov edx,eax
  xor eax,$200000
  push eax
  popfd
  pushfd
  pop eax
  xor eax,edx
  jz @NoCPUID
   // Get cpu features per CPUID opcode
   mov eax,1
   cpuid
   mov dword ptr FeaturesExt,ecx
   mov dword ptr Features,edx
  @NoCPUID:
  popad
 end;
 MMXExt:=(Features and $00800000)<>0;
 SSEExt:=(Features and $02000000)<>0;
 SSE2Ext:=(Features and $04000000)<>0;
 SSE3Ext:=(FeaturesExt and $00000001)<>0;
{$else}
 MMXExt:=false;
 SSEExt:=false;
 SSE2Ext:=false;
 SSE3Ext:=false;
{$endif}
end;

function Vector2(x,y:TKraftScalar):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=x;
 result.y:=y;
end;

function Vector3(x,y,z:TKraftScalar):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
begin
 result.x:=x;
 result.y:=y;
 result.z:=z;
end;

function Vector3(const v:TKraftVector4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v.x;
 result.y:=v.y;
 result.z:=v.z;
end;

function Matrix3x3(const m:TKraftMatrix4x4):TKraftMatrix3x3; overload; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m[0,0];
 result[0,1]:=m[0,1];
 result[0,2]:=m[0,2];
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=m[1,0];
 result[1,1]:=m[1,1];
 result[1,2]:=m[1,2];
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=m[2,0];
 result[2,1]:=m[2,1];
 result[2,2]:=m[2,2];
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function Plane(Normal:TKraftVector3;Distance:TKraftScalar):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
begin
 result.Normal:=Normal;
 result.Distance:=Distance;
end;

function Quaternion(w,x,y,z:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
begin
 result.w:=w;
 result.x:=x;
 result.y:=y;
 result.z:=z;
end;

function Vector2Compare(const v1,v2:TKraftVector2):boolean; {$ifdef caninline}inline;{$endif}
begin
 result:=(abs(v1.x-v2.x)<EPSILON) and (abs(v1.y-v2.y)<EPSILON);
end;

function Vector2CompareEx(const v1,v2:TKraftVector2;const Threshold:TKraftScalar=EPSILON):boolean; {$ifdef caninline}inline;{$endif}
begin
 result:=(abs(v1.x-v2.x)<Threshold) and (abs(v1.y-v2.y)<Threshold);
end;

function Vector2Add(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v1.x+v2.x;
 result.y:=v1.y+v2.y;
end;

function Vector2Sub(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v1.x-v2.x;
 result.y:=v1.y-v2.y;
end;

function Vector2Avg(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(v1.x+v2.x)*0.5;
 result.y:=(v1.y+v2.y)*0.5;
end;

function Vector2ScalarMul(const v:TKraftVector2;s:TKraftScalar):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v.x*s;
 result.y:=v.y*s;
end;

function Vector2Dot(const v1,v2:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=(v1.x*v2.x)+(v1.y*v2.y);
end;

function Vector2Neg(const v:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=-v.x;
 result.y:=-v.y;
end;

procedure Vector2Scale(var v:TKraftVector2;sx,sy:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
begin
 v.x:=v.x*sx;
 v.y:=v.y*sy;
end;

procedure Vector2Scale(var v:TKraftVector2;s:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
begin
 v.x:=v.x*s;
 v.y:=v.y*s;
end;

function Vector2Mul(const v1,v2:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v1.x*v2.x;
 result.y:=v1.y*v2.y;
end;

function Vector2Length(const v:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=sqrt(sqr(v.x)+sqr(v.y));
end;

function Vector2Dist(const v1,v2:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=Vector2Length(Vector2Sub(v2,v1));
end;

function Vector2LengthSquared(const v:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=sqr(v.x)+sqr(v.y);
end;

function Vector2Angle(const v1,v2,v3:TKraftVector2):TKraftScalar; {$ifdef caninline}inline;{$endif}
var A1,A2:TKraftVector2;
    L1,L2:TKraftScalar;
begin
 A1:=Vector2Sub(v1,v2);
 A2:=Vector2Sub(v3,v2);
 L1:=Vector2Length(A1);
 L2:=Vector2Length(A2);
 if (L1=0) or (L2=0) then begin
  result:=0;
 end else begin
  result:=ArcCos(Vector2Dot(A1,A2)/(L1*L2));
 end;
end;

procedure Vector2Normalize(var v:TKraftVector2); {$ifdef caninline}inline;{$endif}
var L:TKraftScalar;
begin
 L:=Vector2Length(v);
 if L<>0.0 then begin
  Vector2Scale(v,1/L);
 end else begin
  v:=Vector2Origin;
 end;
end;

function Vector2Norm(const v:TKraftVector2):TKraftVector2; {$ifdef caninline}inline;{$endif}
var L:TKraftScalar;
begin
 L:=Vector2Length(v);
 if L<>0.0 then begin
  result:=Vector2ScalarMul(v,1/L);
 end else begin
  result:=Vector2Origin;
 end;
end;

procedure Vector2Rotate(var v:TKraftVector2;a:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
var r:TKraftVector2;
begin
 r.x:=(v.x*cos(a))-(v.y*sin(a));
 r.y:=(v.y*cos(a))+(v.x*sin(a));
 v:=r;
end;

procedure Vector2Rotate(var v:TKraftVector2;const Center:TKraftVector2;a:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
var V0,r:TKraftVector2;
begin
 V0:=Vector2Sub(v,Center);
 r.x:=(V0.x*cos(a))-(V0.y*sin(a));
 r.y:=(V0.y*cos(a))+(V0.x*sin(a));
 v:=Vector2Add(r,Center);
end;

procedure Vector2MatrixMul(var v:TKraftVector2;const m:TKraftMatrix2x2); {$ifdef caninline}inline;{$endif}
var t:TKraftVector2;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y);
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y);
 v:=t;
end;

function Vector2TermMatrixMul(const v:TKraftVector2;const m:TKraftMatrix2x2):TKraftVector2; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y);
end;

function Vector2Lerp(const v1,v2:TKraftVector2;w:TKraftScalar):TKraftVector2; {$ifdef caninline}inline;{$endif}
var iw:TKraftScalar;
begin
 if w<0.0 then begin
  result:=v1;
 end else if w>1.0 then begin
  result:=v2;
 end else begin
  iw:=1.0-w;
  result.x:=(iw*v1.x)+(w*v2.x);
  result.y:=(iw*v1.y)+(w*v2.y);
 end;
end;

{$ifdef SIMD}      
function Vector3Flip(const v:TKraftVector3):TKraftVector3;
begin
 result.x:=v.x;
 result.y:=v.z;
 result.z:=-v.y;
end;

const Vector3Mask:array[0..3] of longword=($ffffffff,$ffffffff,$ffffffff,$00000000);

function Vector3Abs(const v:TKraftVector3):TKraftVector3;
begin
 result.x:=abs(v.x);
 result.y:=abs(v.y);
 result.z:=abs(v.z);
end;

function Vector3Compare(const v1,v2:TKraftVector3):boolean;
begin
 result:=(abs(v1.x-v2.x)<EPSILON) and (abs(v1.y-v2.y)<EPSILON) and (abs(v1.z-v2.z)<EPSILON);
end;

function Vector3CompareEx(const v1,v2:TKraftVector3;const Threshold:TKraftScalar=EPSILON):boolean;
begin
 result:=(abs(v1.x-v2.x)<Threshold) and (abs(v1.y-v2.y)<Threshold) and (abs(v1.z-v2.z)<Threshold);
end;

procedure Vector3DirectAdd(var v1:TKraftVector3;const v2:TKraftVector3); {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 addps xmm0,xmm1
 movups dqword ptr [v1],xmm0
end;
{$else}
begin
 v1.x:=v1.x+v2.x;
 v1.y:=v1.y+v2.y;
 v1.z:=v1.z+v2.z;
end;
{$endif}

procedure Vector3DirectSub(var v1:TKraftVector3;const v2:TKraftVector3); {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 subps xmm0,xmm1
 movups dqword ptr [v1],xmm0
end;
{$else}
begin
 v1.x:=v1.x-v2.x;
 v1.y:=v1.y-v2.y;
 v1.z:=v1.z-v2.z;
end;
{$endif}

function Vector3Add(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 addps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=v1.x+v2.x;
 result.y:=v1.y+v2.y;
 result.z:=v1.z+v2.z;
end;
{$endif}

function Vector3Sub(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 subps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=v1.x-v2.x;
 result.y:=v1.y-v2.y;
 result.z:=v1.z-v2.z;
end;
{$endif}

function Vector3Avg(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
const Half:TKraftVector3=(x:0.5;y:0.5;z:0.5;w:0.0);
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 movups xmm2,dqword ptr [Half]
 addps xmm0,xmm1
 mulps xmm0,xmm2
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=(v1.x+v2.x)*0.5;
 result.y:=(v1.y+v2.y)*0.5;
 result.z:=(v1.z+v2.z)*0.5;
end;
{$endif}

function Vector3Avg(const v1,v2,v3:TKraftVector3):TKraftVector3;
begin
 result.x:=(v1.x+v2.x+v3.x)/3.0;
 result.y:=(v1.y+v2.y+v3.y)/3.0;
 result.z:=(v1.z+v2.z+v3.z)/3.0;
end;

function Vector3Avg(const va:PKraftVector3s;Count:longint):TKraftVector3;
var i:longint;
begin
 result.x:=0.0;
 result.y:=0.0;
 result.z:=0.0;
 if Count>0 then begin
  for i:=0 to Count-1 do begin
   result.x:=result.x+va^[i].x;
   result.y:=result.y+va^[i].y;
   result.z:=result.z+va^[i].z;
  end;
  result.x:=result.x/Count;
  result.y:=result.y/Count;
  result.z:=result.z/Count;
 end;
end;

function Vector3ScalarMul(const v:TKraftVector3;const s:TKraftScalar):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movss xmm1,dword ptr [s]
 shufps xmm1,xmm1,$00
 mulps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=v.x*s;
 result.y:=v.y*s;
 result.z:=v.z*s;
end;
{$endif}

function Vector3Dot(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 mulps xmm0,xmm1         // xmm0 = ?, z1*z2, y1*y2, x1*x2
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z1*z2
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z1*z2 + x1*x2
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y1*y2
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z1*z2 + y1*y2 + x1*x2
 movss dword ptr [result],xmm1
end;
{$else}
begin
 result:=(v1.x*v2.x)+(v1.y*v2.y)+(v1.z*v2.z);
end;
{$endif}

function Vector3Cos(const v1,v2:TKraftVector3):TKraftScalar;
var d:extended;
begin
 d:=SQRT(Vector3LengthSquared(v1)*Vector3LengthSquared(v2));
 if d<>0.0 then begin
  result:=((v1.x*v2.x)+(v1.y*v2.y)+(v1.z*v2.z))/d; //result:=Vector3Dot(v1,v2)/d;
 end else begin
  result:=0.9;
 end
end;

function Vector3GetOneUnitOrthogonalVector(const v:TKraftVector3):TKraftVector3;
var MinimumAxis:longint;
    l:TKraftScalar;
begin
 if abs(v.x)<abs(v.y) then begin
  if abs(v.x)<abs(v.z) then begin
   MinimumAxis:=0;
  end else begin
   MinimumAxis:=2;
  end;
 end else begin
  if abs(v.y)<abs(v.z) then begin
   MinimumAxis:=1;
  end else begin
   MinimumAxis:=2;
  end;
 end;
 case MinimumAxis of
  0:begin
   l:=sqrt(sqr(v.y)+sqr(v.z));
   result.x:=0.0;
   result.y:=-(v.z/l);
   result.z:=v.y/l;
  end;
  1:begin
   l:=sqrt(sqr(v.x)+sqr(v.z));
   result.x:=-(v.z/l);
   result.y:=0.0;
   result.z:=v.x/l;
  end;
  else begin
   l:=sqrt(sqr(v.x)+sqr(v.y));
   result.x:=-(v.y/l);
   result.y:=v.x/l;
   result.z:=0.0;
  end;
 end;
 result.w:=0.0;
end;

function Vector3Cross(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
{$ifdef SSEVector3CrossOtherVariant}
 movups xmm0,dqword ptr [v1]
 movups xmm2,dqword ptr [v2]
 movaps xmm1,xmm0
 movaps xmm3,xmm2
 shufps xmm0,xmm0,$c9
 shufps xmm1,xmm1,$d2
 shufps xmm2,xmm2,$d2
 shufps xmm3,xmm3,$c9
 mulps xmm0,xmm2
 mulps xmm1,xmm3
 subps xmm0,xmm1
 movups dqword ptr [result],xmm0
{$else}
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 movaps xmm2,xmm0
 movaps xmm3,xmm1
 shufps xmm0,xmm0,$12
 shufps xmm1,xmm1,$09
 shufps xmm2,xmm2,$09
 shufps xmm3,xmm3,$12
 mulps xmm0,xmm1
 mulps xmm2,xmm3
 subps xmm2,xmm0
 movups dqword ptr [result],xmm2
{$endif}
end;
{$else}
begin
 result.x:=(v1.y*v2.z)-(v1.z*v2.y);
 result.y:=(v1.z*v2.x)-(v1.x*v2.z);
 result.z:=(v1.x*v2.y)-(v1.y*v2.x);
end;
{$endif}

function Vector3Neg(const v:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 xorps xmm0,xmm0
 movups xmm1,dqword ptr [v]
 subps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=-v.x;
 result.y:=-v.y;
 result.z:=-v.z;
end;
{$endif}

procedure Vector3Scale(var v:TKraftVector3;const sx,sy,sz:TKraftScalar); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movss xmm0,dword ptr [v+0]
 movss xmm1,dword ptr [v+4]
 movss xmm2,dword ptr [v+8]
 mulss xmm0,dword ptr [sx]
 mulss xmm1,dword ptr [sy]
 mulss xmm2,dword ptr [sz]
 movss dword ptr [v+0],xmm0
 movss dword ptr [v+4],xmm1
 movss dword ptr [v+8],xmm2
end;
{$else}
begin
 v.x:=v.x*sx;
 v.y:=v.y*sy;
 v.z:=v.z*sz;
end;
{$endif}

procedure Vector3Scale(var v:TKraftVector3;const s:TKraftScalar); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movss xmm1,dword ptr [s]
 shufps xmm1,xmm1,$00
 mulps xmm0,xmm1
 movups dqword ptr [v],xmm0
end;
{$else}
begin
 v.x:=v.x*s;
 v.y:=v.y*s;
 v.z:=v.z*s;
end;
{$endif}

function Vector3Mul(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 mulps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=v1.x*v2.x;
 result.y:=v1.y*v2.y;
 result.z:=v1.z*v2.z;
end;
{$endif}

function Vector3Length(const v:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 sqrtss xmm0,xmm1
 movss dword ptr [result],xmm0
end;
{$else}
begin
 result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z));
end;
{$endif}

function Vector3Dist(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 subps xmm0,xmm1
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 sqrtss xmm0,xmm1
 movss dword ptr [result],xmm0
end;
{$else}
begin
 result:=sqrt(sqr(v2.x-v1.x)+sqr(v2.y-v1.y)+sqr(v2.z-v1.z));
end;
{$endif}

function Vector3LengthSquared(const v:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 movss dword ptr [result],xmm1
end;
{$else}
begin
 result:=sqr(v.x)+sqr(v.y)+sqr(v.z);
end;
{$endif}

function Vector3DistSquared(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v1]
 movups xmm1,dqword ptr [v2]
 subps xmm0,xmm1
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 movss dword ptr [result],xmm1
end;
{$else}
begin
 result:=sqr(v2.x-v1.x)+sqr(v2.y-v1.y)+sqr(v2.z-v1.z);
end;
{$endif}

function Vector3Angle(const v1,v2,v3:TKraftVector3):TKraftScalar;
var A1,A2:TKraftVector3;
    L1,L2:TKraftScalar;
begin
 A1:=Vector3Sub(v1,v2);
 A2:=Vector3Sub(v3,v2);
 L1:=Vector3Length(A1);
 L2:=Vector3Length(A2);
 if (L1=0) or (L2=0) then begin
  result:=0;
 end else begin
  result:=ArcCos(Vector3Dot(A1,A2)/(L1*L2));
 end;
end;

function Vector3LengthNormalize(var v:TKraftVector3):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movaps xmm1,xmm0
 subps xmm1,xmm0
 cmpps xmm1,xmm0,7
 andps xmm0,xmm1
 movaps xmm2,xmm0
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 sqrtss xmm0,xmm1
 movss dword ptr [result],xmm0
 shufps xmm0,xmm0,$00
 divps xmm2,xmm0
 movaps xmm1,xmm2
 subps xmm1,xmm2
 cmpps xmm1,xmm2,7
 andps xmm2,xmm1
 movups dqword ptr [v],xmm2
end;
{$else}
var l:TKraftScalar;
begin
 result:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if result>0.0 then begin
  result:=sqrt(result);
  l:=1.0/result;
  v.x:=v.x*l;
  v.y:=v.y*l;
  v.z:=v.z*l;
 end else begin
  result:=0.0;
  v.x:=0.0;
  v.y:=0.0;
  v.z:=0.0;
 end;
end;
{$endif}

procedure Vector3Normalize(var v:TKraftVector3); {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movaps xmm2,xmm0
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 rsqrtss xmm0,xmm1
 shufps xmm0,xmm0,$00
 mulps xmm2,xmm0
 movaps xmm1,xmm2
 subps xmm1,xmm2
 cmpps xmm1,xmm2,7
 andps xmm2,xmm1
 movups dqword ptr [v],xmm2
end;
{$else}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=1.0/sqrt(l);
  v.x:=v.x*l;
  v.y:=v.y*l;
  v.z:=v.z*l;
 end else begin
  v.x:=0.0;
  v.y:=0.0;
  v.z:=0.0;
 end;
end;
{$endif}
                    
procedure Vector3NormalizeEx(var v:TKraftVector3); {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movaps xmm2,xmm0
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 sqrtss xmm0,xmm1
 shufps xmm0,xmm0,$00
 divps xmm2,xmm0
 movaps xmm1,xmm2
 subps xmm1,xmm2
 cmpps xmm1,xmm2,7
 andps xmm2,xmm1
 movups dqword ptr [v],xmm2
end;
{$else}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=sqrt(l);
  v.x:=v.x/l;
  v.y:=v.y/l;
  v.z:=v.z/l;
 end else begin
  v.x:=0.0;
  v.y:=0.0;
  v.z:=0.0;
 end;
end;
{$endif}

function Vector3SafeNorm(const v:TKraftVector3):TKraftVector3;
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=1.0/sqrt(l);
  result.x:=v.x*l;
  result.y:=v.y*l;
  result.z:=v.z*l;
 end else begin
  result.x:=1.0;
  result.y:=0.0;
  result.z:=0.0;
 end;
end;

function Vector3Norm(const v:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movaps xmm2,xmm0
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 rsqrtss xmm0,xmm1
 shufps xmm0,xmm0,$00
 mulps xmm2,xmm0
 movaps xmm1,xmm2
 subps xmm1,xmm2
 cmpps xmm1,xmm2,7
 andps xmm2,xmm1
 movups dqword ptr [result],xmm2
end;
{$else}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=1.0/sqrt(l);
  result.x:=v.x*l;
  result.y:=v.y*l;
  result.z:=v.z*l;
 end else begin
  result.x:=0.0;
  result.y:=0.0;
  result.z:=0.0;
 end;
end;
{$endif}

function Vector3NormEx(const v:TKraftVector3):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [v]
 movaps xmm2,xmm0
 mulps xmm0,xmm0         // xmm0 = ?, z*z, y*y, x*x
 movhlps xmm1,xmm0       // xmm1 = ?, ?, ?, z*z
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + x*x
 shufps xmm0,xmm0,$55    // xmm0 = ?, ?, ?, y*y
 addss xmm1,xmm0         // xmm1 = ?, ?, ?, z*z + y*y + x*x
 sqrtss xmm0,xmm1
 shufps xmm0,xmm0,$00
 divps xmm2,xmm0
 movaps xmm1,xmm2
 subps xmm1,xmm2
 cmpps xmm1,xmm2,7
 andps xmm2,xmm1
 movups dqword ptr [result],xmm2
end;
{$else}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=sqrt(l);
  result.x:=v.x/l;
  result.y:=v.y/l;
  result.z:=v.z/l;
 end else begin
  result.x:=0.0;
  result.y:=0.0;
  result.z:=0.0;
 end;
end;
{$endif}

procedure Vector3RotateX(var v:TKraftVector3;a:TKraftScalar);
var t:TKraftVector3;
begin
 t.x:=v.x;
 t.y:=(v.y*cos(a))-(v.z*sin(a));
 t.z:=(v.y*sin(a))+(v.z*cos(a));
 v:=t;
end;

procedure Vector3RotateY(var v:TKraftVector3;a:TKraftScalar);
var t:TKraftVector3;
begin
 t.x:=(v.x*cos(a))+(v.z*sin(a));
 t.y:=v.y;
 t.z:=(v.z*cos(a))-(v.x*sin(a));
 v:=t;
end;

procedure Vector3RotateZ(var v:TKraftVector3;a:TKraftScalar);
var t:TKraftVector3;
begin
 t.x:=(v.x*cos(a))-(v.y*sin(a));
 t.y:=(v.x*sin(a))+(v.y*cos(a));
 t.z:=v.z;
 v:=t;
end;

procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix3x3); overload;
var t:TKraftVector3;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
 v:=t;
end;

procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
const cOne:array[0..3] of TKraftScalar=(0.0,0.0,0.0,1.0);
asm
 movups xmm0,dqword ptr [v]     // d c b a
 movups xmm1,dqword ptr [Vector3Mask]
 movups xmm2,dqword ptr [cOne]
 andps xmm0,xmm1
 addps xmm0,xmm2
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 movaps xmm3,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 shufps xmm3,xmm3,$ff           // d d d d 11111111b
 movups xmm4,dqword ptr [m+0]
 movups xmm5,dqword ptr [m+16]
 movups xmm6,dqword ptr [m+32]
 movups xmm7,dqword ptr [m+48]
 mulps xmm0,xmm4
 mulps xmm1,xmm5
 mulps xmm2,xmm6
 mulps xmm3,xmm7
 addps xmm0,xmm1
 addps xmm2,xmm3
 addps xmm0,xmm2
 movups dqword ptr [v],xmm0
end;
{$else}
var t:TKraftVector3;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
 v:=t;
end;
{$endif}

procedure Vector3MatrixMulBasis(var v:TKraftVector3;const m:TKraftMatrix4x4); overload;
var t:TKraftVector3;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
 v:=t;
end;

procedure Vector3MatrixMulInverted(var v:TKraftVector3;const m:TKraftMatrix4x4); overload;
var p,t:TKraftVector3;
begin
 p.x:=v.x-m[3,0];
 p.y:=v.y-m[3,1];
 p.z:=v.z-m[3,2];
 t.x:=(m[0,0]*p.x)+(m[0,1]*p.y)+(m[0,2]*p.z);
 t.y:=(m[1,0]*p.x)+(m[1,1]*p.y)+(m[1,2]*p.z);
 t.z:=(m[2,0]*p.x)+(m[2,1]*p.y)+(m[2,2]*p.z);
 v:=t;
end;

(*
function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
const Mask:array[0..3] of longword=($ffffffff,$ffffffff,$ffffffff,$00000000);
asm
 movups xmm6,dqword ptr [Mask]
 movups xmm0,dqword ptr [v]     // d c b a
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 movups xmm3,dqword ptr [m+0]
 movups xmm4,dqword ptr [m+12]
 andps xmm3,xmm6
 andps xmm4,xmm6
 movss xmm5,dword ptr [m+24]
 movss xmm6,dword ptr [m+28]
 movlhps xmm5,xmm6
 movss xmm6,dword ptr [m+32]
 shufps xmm5,xmm6,$88
 mulps xmm0,xmm3
 mulps xmm1,xmm4
 mulps xmm2,xmm5
 addps xmm0,xmm1
 addps xmm0,xmm2
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
end;
{$endif}
(**)

function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
const cOne:array[0..3] of TKraftScalar=(0.0,0.0,0.0,1.0);
asm
 movups xmm0,dqword ptr [v]     // d c b a
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 movups xmm3,dqword ptr [m+0]
 movups xmm4,dqword ptr [m+16]
 movups xmm5,dqword ptr [m+32]
 mulps xmm0,xmm3
 mulps xmm1,xmm4
 mulps xmm2,xmm5
 addps xmm0,xmm1
 addps xmm0,xmm2
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
end;
{$endif}

function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
const cOne:array[0..3] of TKraftScalar=(0.0,0.0,0.0,1.0);
asm
 movups xmm0,dqword ptr [v]     // d c b a
 movups xmm1,dqword ptr [Vector3Mask]
 movups xmm2,dqword ptr [cOne]
 andps xmm0,xmm1
 addps xmm0,xmm2
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 movaps xmm3,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 shufps xmm3,xmm3,$ff           // d d d d 11111111b
 movups xmm4,dqword ptr [m+0]
 movups xmm5,dqword ptr [m+16]
 movups xmm6,dqword ptr [m+32]
 movups xmm7,dqword ptr [m+48]
 mulps xmm0,xmm4
 mulps xmm1,xmm5
 mulps xmm2,xmm6
 mulps xmm3,xmm7
 addps xmm0,xmm1
 addps xmm2,xmm3
 addps xmm0,xmm2
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
end;
{$endif}

function Vector3TermMatrixMulInverse(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload;
var Determinant:TKraftScalar;
begin
 Determinant:=((m[0,0]*((m[1,1]*m[2,2])-(m[2,1]*m[1,2])))-
               (m[0,1]*((m[1,0]*m[2,2])-(m[2,0]*m[1,2]))))+
               (m[0,2]*((m[1,0]*m[2,1])-(m[2,0]*m[1,1])));
 if Determinant<>0.0 then begin
  Determinant:=1.0/Determinant;
 end;
 result.x:=((v.x*((m[1,1]*m[2,2])-(m[1,2]*m[2,1])))+(v.y*((m[1,2]*m[2,0])-(m[1,0]*m[2,2])))+(v.z*((m[1,0]*m[2,1])-(m[1,1]*m[2,0]))))*Determinant;
 result.y:=((m[0,0]*((v.y*m[2,2])-(v.z*m[2,1])))+(m[0,1]*((v.z*m[2,0])-(v.x*m[2,2])))+(m[0,2]*((v.x*m[2,1])-(v.y*m[2,0]))))*Determinant;
 result.z:=((m[0,0]*((m[1,1]*v.z)-(m[1,2]*v.y)))+(m[0,1]*((m[1,2]*v.x)-(m[1,0]*v.z)))+(m[0,2]*((m[1,0]*v.y)-(m[1,1]*v.x))))*Determinant;
end;

function Vector3TermMatrixMulInverted(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
var p:TKraftVector3;
begin
 p.x:=v.x-m[3,0];
 p.y:=v.y-m[3,1];
 p.z:=v.z-m[3,2];
 result.x:=(m[0,0]*p.x)+(m[0,1]*p.y)+(m[0,2]*p.z);
 result.y:=(m[1,0]*p.x)+(m[1,1]*p.y)+(m[1,2]*p.z);
 result.z:=(m[2,0]*p.x)+(m[2,1]*p.y)+(m[2,2]*p.z);
end;

function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload;
begin
 result.x:=(m[0,0]*v.x)+(m[0,1]*v.y)+(m[0,2]*v.z);
 result.y:=(m[1,0]*v.x)+(m[1,1]*v.y)+(m[1,2]*v.z);
 result.z:=(m[2,0]*v.x)+(m[2,1]*v.y)+(m[2,2]*v.z);
end;

function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
begin
 result.x:=(m[0,0]*v.x)+(m[0,1]*v.y)+(m[0,2]*v.z)+m[0,3];
 result.y:=(m[1,0]*v.x)+(m[1,1]*v.y)+(m[1,2]*v.z)+m[1,3];
 result.z:=(m[2,0]*v.x)+(m[2,1]*v.y)+(m[2,2]*v.z)+m[2,3];
end;

function Vector3TermMatrixMulTransposedBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
begin
 result.x:=(m[0,0]*v.x)+(m[0,1]*v.y)+(m[0,2]*v.z);
 result.y:=(m[1,0]*v.x)+(m[1,1]*v.y)+(m[1,2]*v.z);
 result.z:=(m[2,0]*v.x)+(m[2,1]*v.y)+(m[2,2]*v.z);
end;

function Vector3TermMatrixMulHomogen(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3;
var result_w:TKraftScalar;
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
 result_w:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+m[3,3];
 result.x:=result.x/result_w;
 result.y:=result.y/result_w;
 result.z:=result.z/result_w;
end;

function Vector3TermMatrixMulBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef CPU386ASMForSinglePrecision}assembler;
const Mask:array[0..3] of longword=($ffffffff,$ffffffff,$ffffffff,$00000000);
asm
 movups xmm0,dqword ptr [v]     // d c b a
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 movups xmm3,dqword ptr [m+0]
 movups xmm4,dqword ptr [m+16]
 movups xmm5,dqword ptr [m+32]
 movups xmm6,dqword ptr [Mask]
 andps xmm3,xmm6
 andps xmm4,xmm6
 andps xmm5,xmm6
 mulps xmm0,xmm3
 mulps xmm1,xmm4
 mulps xmm2,xmm5
 addps xmm0,xmm1
 addps xmm0,xmm2
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
end;
{$endif}

function Vector3Lerp(const v1,v2:TKraftVector3;w:TKraftScalar):TKraftVector3;
var iw:TKraftScalar;
begin
 if w<0.0 then begin
  result:=v1;
 end else if w>1.0 then begin
  result:=v2;
 end else begin
  iw:=1.0-w;
  result.x:=(iw*v1.x)+(w*v2.x);
  result.y:=(iw*v1.y)+(w*v2.y);
  result.z:=(iw*v1.z)+(w*v2.z);
 end;
end;

function Vector3Perpendicular(v:TKraftVector3):TKraftVector3;
var p:TKraftVector3;
begin
 Vector3NormalizeEx(v);
 p.x:=abs(v.x);
 p.y:=abs(v.y);
 p.z:=abs(v.z);
 if (p.x<=p.y) and (p.x<=p.z) then begin
  p:=Vector3XAxis;
 end else if (p.y<=p.x) and (p.y<=p.z) then begin
  p:=Vector3YAxis;
 end else begin
  p:=Vector3ZAxis;
 end;
 result:=Vector3NormEx(Vector3Sub(p,Vector3ScalarMul(v,Vector3Dot(v,p))));
end;

function Vector3TermQuaternionRotate(const v:TKraftVector3;const q:TKraftQuaternion):TKraftVector3; {$ifdef CPU386ASMForSinglePrecision}assembler;
const Mask:array[0..3] of longword=($ffffffff,$ffffffff,$ffffffff,$00000000);
var t,qv:TKraftVector3;
asm

 movups xmm4,dqword ptr [q] // xmm4 = q.xyzw

 movups xmm5,dqword ptr [v] // xmm5 = v.xyz?

 movaps xmm6,xmm4
 shufps xmm6,xmm6,$ff // xmm6 = q.wwww

 movups xmm7,dqword ptr [Mask] // xmm7 = Mask

 andps xmm4,xmm7 // xmm4 = q.xyz0

 andps xmm5,xmm7 // xmm5 = v.xyz0

 // t:=Vector3ScalarMul(Vector3Cross(qv,v),2.0);
 movaps xmm0,xmm4 // xmm4 = qv
 movaps xmm1,xmm5 // xmm5 = v
 movaps xmm2,xmm4 // xmm4 = qv
 movaps xmm3,xmm5 // xmm5 = v
 shufps xmm0,xmm0,$12
 shufps xmm1,xmm1,$09
 shufps xmm2,xmm2,$09
 shufps xmm3,xmm3,$12
 mulps xmm0,xmm1
 mulps xmm2,xmm3
 subps xmm2,xmm0
 addps xmm2,xmm2

 // xmm6 = Vector3Add(v,Vector3ScalarMul(t,q.w))
 mulps xmm6,xmm2 // xmm6 = q.wwww, xmm2 = t
 addps xmm6,xmm5 // xmm5 = v

 // Vector3Cross(qv,t)
 movaps xmm1,xmm4 // xmm4 = qv
 movaps xmm3,xmm2 // xmm2 = t
 shufps xmm4,xmm4,$12
 shufps xmm2,xmm2,$09
 shufps xmm1,xmm1,$09
 shufps xmm3,xmm3,$12
 mulps xmm4,xmm2
 mulps xmm1,xmm3
 subps xmm1,xmm4

 // result:=Vector3Add(Vector3Add(v,Vector3ScalarMul(t,q.w)),Vector3Cross(qv,t));
 addps xmm1,xmm6

 movups dqword ptr [result],xmm1

end;
{$else}
var t,qv:TKraftVector3;
begin
 // t = 2 * cross(q.xyz, v)
 // v' = v + q.w * t + cross(q.xyz, t)
 qv.x:=q.x;
 qv.y:=q.y;
 qv.z:=q.z;
 qv.w:=0.0;
 t:=Vector3ScalarMul(Vector3Cross(qv,v),2.0);
 result:=Vector3Add(Vector3Add(v,Vector3ScalarMul(t,q.w)),Vector3Cross(qv,t));
end;
{$endif}

function Vector3ProjectToBounds(const v:TKraftVector3;const MinVector,MaxVector:TKraftVector3):TKraftScalar;
begin
 if v.x<0.0 then begin
  result:=v.x*MaxVector.x;
 end else begin
  result:=v.x*MinVector.x;
 end;
 if v.y<0.0 then begin
  result:=result+(v.y*MaxVector.y);
 end else begin
  result:=result+(v.y*MinVector.y);
 end;
 if v.z<0.0 then begin
  result:=result+(v.z*MaxVector.z);
 end else begin
  result:=result+(v.z*MinVector.z);
 end;
end;
{$else}
function Vector3Flip(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v.x;
 result.y:=v.z;
 result.z:=-v.y;
end;

function Vector3Abs(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=abs(v.x);
 result.y:=abs(v.y);
 result.z:=abs(v.z);
end;

function Vector3Compare(const v1,v2:TKraftVector3):boolean; {$ifdef caninline}inline;{$endif}
begin
 result:=(abs(v1.x-v2.x)<EPSILON) and (abs(v1.y-v2.y)<EPSILON) and (abs(v1.z-v2.z)<EPSILON);
end;

function Vector3CompareEx(const v1,v2:TKraftVector3;const Threshold:TKraftScalar=EPSILON):boolean; {$ifdef caninline}inline;{$endif}
begin
 result:=(abs(v1.x-v2.x)<Threshold) and (abs(v1.y-v2.y)<Threshold) and (abs(v1.z-v2.z)<Threshold);
end;

function Vector3DirectAdd(var v1:TKraftVector3;const v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 v1.x:=v1.x+v2.x;
 v1.y:=v1.y+v2.y;
 v1.z:=v1.z+v2.z;
end;

function Vector3DirectSub(var v1:TKraftVector3;const v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 v1.x:=v1.x-v2.x;
 v1.y:=v1.y-v2.y;
 v1.z:=v1.z-v2.z;
end;

function Vector3Add(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v1.x+v2.x;
 result.y:=v1.y+v2.y;
 result.z:=v1.z+v2.z;
end;

function Vector3Sub(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v1.x-v2.x;
 result.y:=v1.y-v2.y;
 result.z:=v1.z-v2.z;
end;

function Vector3Avg(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(v1.x+v2.x)*0.5;
 result.y:=(v1.y+v2.y)*0.5;
 result.z:=(v1.z+v2.z)*0.5;
end;

function Vector3Avg(const v1,v2,v3:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(v1.x+v2.x+v3.x)/3.0;
 result.y:=(v1.y+v2.y+v3.y)/3.0;
 result.z:=(v1.z+v2.z+v3.z)/3.0;
end;

function Vector3Avg(const va:PKraftVector3s;Count:longint):TKraftVector3; {$ifdef caninline}inline;{$endif}
var i:longint;
begin
 result.x:=0.0;
 result.y:=0.0;
 result.z:=0.0;
 if Count>0 then begin
  for i:=0 to Count-1 do begin
   result.x:=result.x+va^[i].x;
   result.y:=result.y+va^[i].y;
   result.z:=result.z+va^[i].z;
  end;
  result.x:=result.x/Count;
  result.y:=result.y/Count;
  result.z:=result.z/Count;
 end;
end;

function Vector3ScalarMul(const v:TKraftVector3;const s:TKraftScalar):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v.x*s;
 result.y:=v.y*s;
 result.z:=v.z*s;
end;

function Vector3Dot(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=(v1.x*v2.x)+(v1.y*v2.y)+(v1.z*v2.z);
end;

function Vector3Cos(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
var d:extended;
begin
 d:=SQRT(Vector3LengthSquared(v1)*Vector3LengthSquared(v2));
 if d<>0.0 then begin
  result:=((v1.x*v2.x)+(v1.y*v2.y)+(v1.z*v2.z))/d; //result:=Vector3Dot(v1,v2)/d;
 end else begin
  result:=0.0;
 end
end;

function Vector3GetOneUnitOrthogonalVector(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
var MinimumAxis:longint;
    l:TKraftScalar;
begin
 if abs(v.x)<abs(v.y) then begin
  if abs(v.x)<abs(v.z) then begin
   MinimumAxis:=0;
  end else begin
   MinimumAxis:=2;
  end;
 end else begin
  if abs(v.y)<abs(v.z) then begin
   MinimumAxis:=1;
  end else begin
   MinimumAxis:=2;
  end;
 end;
 case MinimumAxis of
  0:begin
   l:=sqrt(sqr(v.y)+sqr(v.z));
   result.x:=0.0;
   result.y:=-(v.z/l);
   result.z:=v.y/l;
  end;
  1:begin
   l:=sqrt(sqr(v.x)+sqr(v.z));
   result.x:=-(v.z/l);
   result.y:=0.0;
   result.z:=v.x/l;
  end;
  else begin
   l:=sqrt(sqr(v.x)+sqr(v.y));
   result.x:=-(v.y/l);
   result.y:=v.x/l;
   result.z:=0.0;
  end;
 end;
end;

function Vector3Cross(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(v1.y*v2.z)-(v1.z*v2.y);
 result.y:=(v1.z*v2.x)-(v1.x*v2.z);
 result.z:=(v1.x*v2.y)-(v1.y*v2.x);
end;

function Vector3Neg(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=-v.x;
 result.y:=-v.y;
 result.z:=-v.z;
end;

procedure Vector3Scale(var v:TKraftVector3;const sx,sy,sz:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
begin
 v.x:=v.x*sx;
 v.y:=v.y*sy;
 v.z:=v.z*sz;
end;

procedure Vector3Scale(var v:TKraftVector3;const s:TKraftScalar); overload; {$ifdef caninline}inline;{$endif}
begin
 v.x:=v.x*s;
 v.y:=v.y*s;
 v.z:=v.z*s;
end;

function Vector3Mul(const v1,v2:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=v1.x*v2.x;
 result.y:=v1.y*v2.y;
 result.z:=v1.z*v2.z;
end;

function Vector3Length(const v:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z));
end;

function Vector3Dist(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=sqrt(sqr(v2.x-v1.x)+sqr(v2.y-v1.y)+sqr(v2.z-v1.z));
end;

function Vector3LengthSquared(const v:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=sqr(v.x)+sqr(v.y)+sqr(v.z);
end;

function Vector3DistSquared(const v1,v2:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=sqr(v2.x-v1.x)+sqr(v2.y-v1.y)+sqr(v2.z-v1.z);
end;

function Vector3Angle(const v1,v2,v3:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
var A1,A2:TKraftVector3;
    L1,L2:TKraftScalar;
begin
 A1:=Vector3Sub(v1,v2);
 A2:=Vector3Sub(v3,v2);
 L1:=Vector3Length(A1);
 L2:=Vector3Length(A2);
 if (L1=0) or (L2=0) then begin
  result:=0;
 end else begin
  result:=ArcCos(Vector3Dot(A1,A2)/(L1*L2));
 end;
end;

function Vector3LengthNormalize(var v:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
var l:TKraftScalar;
begin
 result:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if result>0.0 then begin
  result:=sqrt(result);
  l:=1.0/result;
  v.x:=v.x*l;
  v.y:=v.y*l;
  v.z:=v.z*l;
 end else begin
  result:=0.0;
  v.x:=0.0;
  v.y:=0.0;
  v.z:=0.0;
 end;
end;

procedure Vector3Normalize(var v:TKraftVector3); {$ifdef caninline}inline;{$endif}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=1.0/sqrt(l);
  v.x:=v.x*l;
  v.y:=v.y*l;
  v.z:=v.z*l;
 end else begin
  v.x:=0.0;
  v.y:=0.0;
  v.z:=0.0;
 end;
end;

procedure Vector3NormalizeEx(var v:TKraftVector3); {$ifdef caninline}inline;{$endif}
var l:single;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=sqrt(l);
  v.x:=v.x/l;
  v.y:=v.y/l;
  v.z:=v.z/l;
 end else begin
  v.x:=0.0;
  v.y:=0.0;
  v.z:=0.0;
 end;
end;

function Vector3SafeNorm(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=1.0/sqrt(l);
  result.x:=v.x*l;
  result.y:=v.y*l;
  result.z:=v.z*l;
 end else begin
  result.x:=1.0;
  result.y:=0.0;
  result.z:=0.0;
 end;
end;

function Vector3Norm(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=1.0/sqrt(l);
  result.x:=v.x*l;
  result.y:=v.y*l;
  result.z:=v.z*l;
 end else begin
  result.x:=0.0;
  result.y:=0.0;
  result.z:=0.0;
 end;
end;

function Vector3NormEx(const v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
var l:TKraftScalar;
begin
 l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 if l>0.0 then begin
  l:=sqrt(l);
  result.x:=v.x/l;
  result.y:=v.y/l;
  result.z:=v.z/l;
 end else begin
  result.x:=0.0;
  result.y:=0.0;
  result.z:=0.0;
 end;
end;

procedure Vector3RotateX(var v:TKraftVector3;a:TKraftScalar); {$ifdef caninline}inline;{$endif}
var t:TKraftVector3;
begin
 t.x:=v.x;
 t.y:=(v.y*cos(a))-(v.z*sin(a));
 t.z:=(v.y*sin(a))+(v.z*cos(a));
 v:=t;
end;

procedure Vector3RotateY(var v:TKraftVector3;a:TKraftScalar); {$ifdef caninline}inline;{$endif}
var t:TKraftVector3;
begin
 t.x:=(v.x*cos(a))+(v.z*sin(a));
 t.y:=v.y;
 t.z:=(v.z*cos(a))-(v.x*sin(a));
 v:=t;
end;

procedure Vector3RotateZ(var v:TKraftVector3;a:TKraftScalar); {$ifdef caninline}inline;{$endif}
var t:TKraftVector3;
begin
 t.x:=(v.x*cos(a))-(v.y*sin(a));
 t.y:=(v.x*sin(a))+(v.y*cos(a));
 t.z:=v.z;
 v:=t;
end;

procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix3x3); overload; {$ifdef caninline}inline;{$endif}
var t:TKraftVector3;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
 v:=t;
end;

procedure Vector3MatrixMul(var v:TKraftVector3;const m:TKraftMatrix4x4); overload;
var t:TKraftVector3;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
 v:=t;
end;

procedure Vector3MatrixMulBasis(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef caninline}inline;{$endif}
var t:TKraftVector3;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
 v:=t;
end;

procedure Vector3MatrixMulInverted(var v:TKraftVector3;const m:TKraftMatrix4x4); overload; {$ifdef caninline}inline;{$endif}
var p,t:TKraftVector3;
begin
 p.x:=v.x-m[3,0];
 p.y:=v.y-m[3,1];
 p.z:=v.z-m[3,2];
 t.x:=(m[0,0]*p.x)+(m[0,1]*p.y)+(m[0,2]*p.z);
 t.y:=(m[1,0]*p.x)+(m[1,1]*p.y)+(m[1,2]*p.z);
 t.z:=(m[2,0]*p.x)+(m[2,1]*p.y)+(m[2,2]*p.z);
 v:=t;
end;

function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
end;

function Vector3TermMatrixMulInverse(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
var Determinant:TKraftScalar;
begin
 Determinant:=((m[0,0]*((m[1,1]*m[2,2])-(m[2,1]*m[1,2])))-
               (m[0,1]*((m[1,0]*m[2,2])-(m[2,0]*m[1,2]))))+
               (m[0,2]*((m[1,0]*m[2,1])-(m[2,0]*m[1,1])));
 if Determinant<>0.0 then begin
  Determinant:=1.0/Determinant;
 end;
 result.x:=((v.x*((m[1,1]*m[2,2])-(m[1,2]*m[2,1])))+(v.y*((m[1,2]*m[2,0])-(m[1,0]*m[2,2])))+(v.z*((m[1,0]*m[2,1])-(m[1,1]*m[2,0]))))*Determinant;
 result.y:=((m[0,0]*((v.y*m[2,2])-(v.z*m[2,1])))+(m[0,1]*((v.z*m[2,0])-(v.x*m[2,2])))+(m[0,2]*((v.x*m[2,1])-(v.y*m[2,0]))))*Determinant;
 result.z:=((m[0,0]*((m[1,1]*v.z)-(m[1,2]*v.y)))+(m[0,1]*((m[1,2]*v.x)-(m[1,0]*v.z)))+(m[0,2]*((m[1,0]*v.y)-(m[1,1]*v.x))))*Determinant;
end;

function Vector3TermMatrixMulInverted(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
var p:TKraftVector3;
begin
 p.x:=v.x-m[3,0];
 p.y:=v.y-m[3,1];
 p.z:=v.z-m[3,2];
 result.x:=(m[0,0]*p.x)+(m[0,1]*p.y)+(m[0,2]*p.z);
 result.y:=(m[1,0]*p.x)+(m[1,1]*p.y)+(m[1,2]*p.z);
 result.z:=(m[2,0]*p.x)+(m[2,1]*p.y)+(m[2,2]*p.z);
end;

function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix3x3):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(m[0,0]*v.x)+(m[0,1]*v.y)+(m[0,2]*v.z);
 result.y:=(m[1,0]*v.x)+(m[1,1]*v.y)+(m[1,2]*v.z);
 result.z:=(m[2,0]*v.x)+(m[2,1]*v.y)+(m[2,2]*v.z);
end;

function Vector3TermMatrixMulTransposed(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(m[0,0]*v.x)+(m[0,1]*v.y)+(m[0,2]*v.z)+m[0,3];
 result.y:=(m[1,0]*v.x)+(m[1,1]*v.y)+(m[1,2]*v.z)+m[1,3];
 result.z:=(m[2,0]*v.x)+(m[2,1]*v.y)+(m[2,2]*v.z)+m[2,3];
end;

function Vector3TermMatrixMulTransposedBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(m[0,0]*v.x)+(m[0,1]*v.y)+(m[0,2]*v.z);
 result.y:=(m[1,0]*v.x)+(m[1,1]*v.y)+(m[1,2]*v.z);
 result.z:=(m[2,0]*v.x)+(m[2,1]*v.y)+(m[2,2]*v.z);
end;

function Vector3TermMatrixMulHomogen(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; {$ifdef caninline}inline;{$endif}
var result_w:TKraftScalar;
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
 result_w:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+m[3,3];
 result.x:=result.x/result_w;
 result.y:=result.y/result_w;
 result.z:=result.z/result_w;
end;

function Vector3TermMatrixMulBasis(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z);
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z);
end;

function Vector3TermMatrixMul(const v:TKraftVector3;const m:TKraftMatrix4x4):TKraftVector3; overload;
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
end;

function Vector3Lerp(const v1,v2:TKraftVector3;w:TKraftScalar):TKraftVector3; {$ifdef caninline}inline;{$endif}
var iw:TKraftScalar;
begin
 if w<0.0 then begin
  result:=v1;
 end else if w>1.0 then begin
  result:=v2;
 end else begin
  iw:=1.0-w;
  result.x:=(iw*v1.x)+(w*v2.x);
  result.y:=(iw*v1.y)+(w*v2.y);
  result.z:=(iw*v1.z)+(w*v2.z);
 end;
end;

function Vector3Perpendicular(v:TKraftVector3):TKraftVector3; {$ifdef caninline}inline;{$endif}
var p:TKraftVector3;
begin
 Vector3NormalizeEx(v);
 p.x:=abs(v.x);
 p.y:=abs(v.y);
 p.z:=abs(v.z);
 if (p.x<=p.y) and (p.x<=p.z) then begin
  p:=Vector3XAxis;
 end else if (p.y<=p.x) and (p.y<=p.z) then begin
  p:=Vector3YAxis;
 end else begin
  p:=Vector3ZAxis;
 end;
 result:=Vector3NormEx(Vector3Sub(p,Vector3ScalarMul(v,Vector3Dot(v,p))));
end;

function Vector3TermQuaternionRotate(const v:TKraftVector3;const q:TKraftQuaternion):TKraftVector3; {$ifdef caninline}inline;{$endif}
var t,qv:TKraftVector3;
begin
 // t = 2 * cross(q.xyz, v)
 // v' = v + q.w * t + cross(q.xyz, t)
 qv:=PKraftVector3(pointer(@q))^;
 t:=Vector3ScalarMul(Vector3Cross(qv,v),2.0);
 result:=Vector3Add(Vector3Add(v,Vector3ScalarMul(t,q.w)),Vector3Cross(qv,t));
end;
{var vn:TKraftVector3;
vq,rq:TKraftQuaternion;
begin
 vq.x:=vn.x;
 vq.y:=vn.y;
 vq.z:=vn.z;
 vq.w:=0.0;
 rq:=QuaternionMul(q,QuaternionMul(vq,QuaternionConjugate(q)));
 result.x:=rq.x;
 result.y:=rq.y;
 result.z:=rq.z;
end;{}

function Vector3ProjectToBounds(const v:TKraftVector3;const MinVector,MaxVector:TKraftVector3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 if v.x<0.0 then begin
  result:=v.x*MaxVector.x;
 end else begin
  result:=v.x*MinVector.x;
 end;
 if v.y<0.0 then begin
  result:=result+(v.y*MaxVector.y);
 end else begin
  result:=result+(v.y*MinVector.y);
 end;
 if v.z<0.0 then begin
  result:=result+(v.z*MaxVector.z);
 end else begin
  result:=result+(v.z*MinVector.z);
 end;
end;
{$endif}

function Vector4Compare(const v1,v2:TKraftVector4):boolean;
begin
 result:=(abs(v1.x-v2.x)<EPSILON) and (abs(v1.y-v2.y)<EPSILON) and (abs(v1.z-v2.z)<EPSILON) and (abs(v1.w-v2.w)<EPSILON);
end;

function Vector4CompareEx(const v1,v2:TKraftVector4;const Threshold:TKraftScalar=EPSILON):boolean;
begin
 result:=(abs(v1.x-v2.x)<Threshold) and (abs(v1.y-v2.y)<Threshold) and (abs(v1.z-v2.z)<Threshold) and (abs(v1.w-v2.w)<Threshold);
end;

function Vector4Add(const v1,v2:TKraftVector4):TKraftVector4;
begin
 result.x:=v1.x+v2.x;
 result.y:=v1.y+v2.y;
 result.z:=v1.z+v2.z;
 result.w:=v1.w+v2.w;
end;

function Vector4Sub(const v1,v2:TKraftVector4):TKraftVector4;
begin
 result.x:=v1.x-v2.x;
 result.y:=v1.y-v2.y;
 result.z:=v1.z-v2.z;
 result.w:=v1.w-v2.w;
end;

function Vector4ScalarMul(const v:TKraftVector4;s:TKraftScalar):TKraftVector4;
begin
 result.x:=v.x*s;
 result.y:=v.y*s;
 result.z:=v.z*s;
 result.w:=v.w*s;
end;

function Vector4Dot(const v1,v2:TKraftVector4):TKraftScalar;
begin
 result:=(v1.x*v2.x)+(v1.y*v2.y)+(v1.z*v2.z)+(v1.w*v2.w);
end;

function Vector4Cross(const v1,v2:TKraftVector4):TKraftVector4;
begin
 result.x:=(v1.y*v2.z)-(v2.y*v1.z);
 result.y:=(v2.x*v1.z)-(v1.x*v2.z);
 result.z:=(v1.x*v2.y)-(v2.x*v1.y);
 result.w:=1;
end;

function Vector4Neg(const v:TKraftVector4):TKraftVector4;
begin
 result.x:=-v.x;
 result.y:=-v.y;
 result.z:=-v.z;
 result.w:=1;
end;

procedure Vector4Scale(var v:TKraftVector4;sx,sy,sz:TKraftScalar); overload;
begin
 v.x:=v.x*sx;
 v.y:=v.y*sy;
 v.z:=v.z*sz;
end;

procedure Vector4Scale(var v:TKraftVector4;s:TKraftScalar); overload;
begin
 v.x:=v.x*s;
 v.y:=v.y*s;
 v.z:=v.z*s;
end;

function Vector4Mul(const v1,v2:TKraftVector4):TKraftVector4;
begin
 result.x:=v1.x*v2.x;
 result.y:=v1.y*v2.y;
 result.z:=v1.z*v2.z;
 result.w:=1;
end;

function Vector4Length(const v:TKraftVector4):TKraftScalar;
begin
 result:=SQRT((v.x*v.x)+(v.y*v.y)+(v.z*v.z));
end;

function Vector4Dist(const v1,v2:TKraftVector4):TKraftScalar;
begin
 result:=Vector4Length(Vector4Sub(v2,v1));
end;

function Vector4LengthSquared(const v:TKraftVector4):TKraftScalar;
begin
 result:=(v.x*v.x)+(v.y*v.y)+(v.z*v.z);
end;

function Vector4DistSquared(const v1,v2:TKraftVector4):TKraftScalar;
begin
 result:=Vector4LengthSquared(Vector4Sub(v2,v1));
end;

function Vector4Angle(const v1,v2,v3:TKraftVector4):TKraftScalar;
var A1,A2:TKraftVector4;
    L1,L2:TKraftScalar;
begin
 A1:=Vector4Sub(v1,v2);
 A2:=Vector4Sub(v3,v2);
 L1:=Vector4Length(A1);
 L2:=Vector4Length(A2);
 if (L1=0) or (L2=0) then begin
  result:=0;
 end else begin
  result:=ArcCos(Vector4Dot(A1,A2)/(L1*L2));
 end;
end;

procedure Vector4Normalize(var v:TKraftVector4);
var L:TKraftScalar;
begin
 L:=Vector4Length(v);
 if L<>0.0 then begin
  Vector4Scale(v,1/L);
 end else begin
  v:=Vector4Origin;
 end;
end;

function Vector4Norm(const v:TKraftVector4):TKraftVector4;
var L:TKraftScalar;
begin
 L:=Vector4Length(v);
 if L<>0.0 then begin
  result:=Vector4ScalarMul(v,1/L);
 end else begin
  result:=Vector4Origin;
 end;
end;

procedure Vector4RotateX(var v:TKraftVector4;a:TKraftScalar);
var t:TKraftVector4;
begin
 t.x:=v.x;
 t.y:=(v.y*cos(a))+(v.z*-sin(a));
 t.z:=(v.y*sin(a))+(v.z*cos(a));
 t.w:=1;
 v:=t;
end;

procedure Vector4RotateY(var v:TKraftVector4;a:TKraftScalar);
var t:TKraftVector4;
begin
 t.x:=(v.x*cos(a))+(v.z*sin(a));
 t.y:=v.y;
 t.z:=(v.x*-sin(a))+(v.z*cos(a));
 t.w:=1;
 v:=t;
end;

procedure Vector4RotateZ(var v:TKraftVector4;a:TKraftScalar);
var t:TKraftVector4;
begin
 t.x:=(v.x*cos(a))+(v.y*-sin(a));
 t.y:=(v.x*sin(a))+(v.y*cos(a));
 t.z:=v.z;
 t.w:=1;
 v:=t;
end;

procedure Vector4MatrixMul(var v:TKraftVector4;const m:TKraftMatrix4x4); {$ifdef CPU386ASMForSinglePrecision}register;
asm
{mov eax,v
 mov edx,m}
 movups xmm0,dqword ptr [v]     // d c b a
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 movaps xmm3,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 shufps xmm3,xmm3,$ff           // d d d d 11111111b
 movups xmm4,dqword ptr [m+0]
 movups xmm5,dqword ptr [m+16]
 movups xmm6,dqword ptr [m+32]
 movups xmm7,dqword ptr [m+48]
 mulps xmm0,xmm4
 mulps xmm1,xmm5
 mulps xmm2,xmm6
 mulps xmm3,xmm7
 addps xmm0,xmm1
 addps xmm2,xmm3
 addps xmm0,xmm2
 movups dqword ptr [v],xmm0
end;
{$else}
var t:TKraftVector4;
begin
 t.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+(m[3,0]*v.w);
 t.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+(m[3,1]*v.w);
 t.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+(m[3,2]*v.w);
 t.w:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+(m[3,3]*v.w);
 v:=t;
end;
{$endif}

function Vector4TermMatrixMul(const v:TKraftVector4;const m:TKraftMatrix4x4):TKraftVector4; {$ifdef CPU386ASMForSinglePrecision}register;
asm
{mov eax,v
 mov edx,m
 mov ecx,result}
 movups xmm0,[eax]              // d c b a
 movaps xmm1,xmm0               // d c b a
 movaps xmm2,xmm0               // d c b a
 movaps xmm3,xmm0               // d c b a
 shufps xmm0,xmm0,$00           // a a a a 00000000b
 shufps xmm1,xmm1,$55           // b b b b 01010101b
 shufps xmm2,xmm2,$aa           // c c c c 10101010b
 shufps xmm3,xmm3,$ff           // d d d d 11111111b
 movups xmm4,[edx+0]
 movups xmm5,[edx+16]
 movups xmm6,[edx+32]
 movups xmm7,[edx+48]
 mulps xmm0,xmm4
 mulps xmm1,xmm5
 mulps xmm2,xmm6
 mulps xmm3,xmm7
 addps xmm0,xmm1
 addps xmm2,xmm3
 addps xmm0,xmm2
 movups [ecx],xmm0
end;
{$else}
begin
 result.x:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+(m[3,0]*v.w);
 result.y:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+(m[3,1]*v.w);
 result.z:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+(m[3,2]*v.w);
 result.w:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+(m[3,3]*v.w);
end;
{$endif}

function Vector4TermMatrixMulHomogen(const v:TKraftVector4;const m:TKraftMatrix4x4):TKraftVector4;
begin
 result.w:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+(m[3,3]*v.w);
 result.x:=((m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+(m[3,0]*v.w))/result.w;
 result.y:=((m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+(m[3,1]*v.w))/result.w;
 result.z:=((m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+(m[3,2]*v.w))/result.w;
 result.w:=1.0;
end;

procedure Vector4Rotate(var v:TKraftVector4;const Axis:TKraftVector4;a:TKraftScalar);
var t:TKraftVector3;
begin
 t.x:=Axis.x;
 t.y:=Axis.y;
 t.z:=Axis.z;
 Vector4MatrixMul(v,Matrix4x4Rotate(a,t));
end;

function Vector4Lerp(const v1,v2:TKraftVector4;w:TKraftScalar):TKraftVector4;
var iw:TKraftScalar;
begin
 if w<0.0 then begin
  result:=v1;
 end else if w>1.0 then begin
  result:=v2;
 end else begin
  iw:=1.0-w;
  result.x:=(iw*v1.x)+(w*v2.x);
  result.y:=(iw*v1.y)+(w*v2.y);
  result.z:=(iw*v1.z)+(w*v2.z);
  result.w:=(iw*v1.w)+(w*v2.w);
 end;
end;

function Matrix2x2Inverse(var mr:TKraftMatrix2x2;const ma:TKraftMatrix2x2):boolean;
var Determinant:TKraftScalar;
begin
 Determinant:=(ma[0,0]*ma[1,1])-(ma[0,1]*ma[1,0]);
 if abs(Determinant)<EPSILON then begin
  mr:=Matrix2x2Identity;
  result:=false;
 end else begin
  Determinant:=1.0/Determinant;
  mr[0,0]:=ma[1,1]*Determinant;
  mr[0,1]:=-(ma[0,1]*Determinant);
  mr[1,0]:=-(ma[1,0]*Determinant);
  mr[1,1]:=ma[0,0]*Determinant;
  result:=true;
 end;
end;

function Matrix2x2TermInverse(const m:TKraftMatrix2x2):TKraftMatrix2x2;
var Determinant:TKraftScalar;
begin
 Determinant:=(m[0,0]*m[1,1])-(m[0,1]*m[1,0]);
 if abs(Determinant)<EPSILON then begin
  result:=Matrix2x2Identity;
 end else begin
  Determinant:=1.0/Determinant;
  result[0,0]:=m[1,1]*Determinant;
  result[0,1]:=-(m[0,1]*Determinant);
  result[1,0]:=-(m[1,0]*Determinant);
  result[1,1]:=m[0,0]*Determinant;
 end;
end;

function Matrix3x3RotateX(Angle:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix3x3Identity;
 result[1,1]:=cos(Angle);
 result[2,2]:=result[1,1];
 result[1,2]:=sin(Angle);
 result[2,1]:=-result[1,2];
end;

function Matrix3x3RotateY(Angle:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix3x3Identity;
 result[0,0]:=cos(Angle);
 result[2,2]:=result[0,0];
 result[0,2]:=-sin(Angle);
 result[2,0]:=-result[0,2];
end;

function Matrix3x3RotateZ(Angle:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix3x3Identity;
 result[0,0]:=cos(Angle);
 result[1,1]:=result[0,0];
 result[0,1]:=sin(Angle);
 result[1,0]:=-result[0,1];
end;

function Matrix3x3Rotate(Angle:TKraftScalar;Axis:TKraftVector3):TKraftMatrix3x3; overload;
var m:TKraftMatrix3x3;
    CosinusAngle,SinusAngle:TKraftScalar;
begin
 m:=Matrix3x3Identity;
 CosinusAngle:=cos(Angle);
 SinusAngle:=sin(Angle);
 m[0,0]:=CosinusAngle+((1.0-CosinusAngle)*sqr(Axis.x));
 m[1,0]:=((1.0-CosinusAngle)*Axis.x*Axis.y)-(Axis.z*SinusAngle);
 m[2,0]:=((1.0-CosinusAngle)*Axis.x*Axis.z)+(Axis.y*SinusAngle);
 m[0,1]:=((1.0-CosinusAngle)*Axis.x*Axis.z)+(Axis.z*SinusAngle);
 m[1,1]:=CosinusAngle+((1.0-CosinusAngle)*sqr(Axis.y));
 m[2,1]:=((1.0-CosinusAngle)*Axis.y*Axis.z)-(Axis.x*SinusAngle);
 m[0,2]:=((1.0-CosinusAngle)*Axis.x*Axis.z)-(Axis.y*SinusAngle);
 m[1,2]:=((1.0-CosinusAngle)*Axis.y*Axis.z)+(Axis.x*SinusAngle);
 m[2,2]:=CosinusAngle+((1.0-CosinusAngle)*sqr(Axis.z));
{$ifdef SIMD}
 m[0,3]:=0.0;
 m[1,3]:=0.0;
 m[2,3]:=0.0;
{$endif}
 result:=m;
end;

function Matrix3x3Scale(sx,sy,sz:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix3x3Identity;
 result[0,0]:=sx;
 result[1,1]:=sy;
 result[2,2]:=sz;
end;

procedure Matrix3x3Add(var m1:TKraftMatrix3x3;const m2:TKraftMatrix3x3); {$ifdef caninline}inline;{$endif}
begin
 m1[0,0]:=m1[0,0]+m2[0,0];
 m1[0,1]:=m1[0,1]+m2[0,1];
 m1[0,2]:=m1[0,2]+m2[0,2];
{$ifdef SIMD}
 m1[0,3]:=0.0;
{$endif}
 m1[1,0]:=m1[1,0]+m2[1,0];
 m1[1,1]:=m1[1,1]+m2[1,1];
 m1[1,2]:=m1[1,2]+m2[1,2];
{$ifdef SIMD}
 m1[1,3]:=0.0;
{$endif}
 m1[2,0]:=m1[2,0]+m2[2,0];
 m1[2,1]:=m1[2,1]+m2[2,1];
 m1[2,2]:=m1[2,2]+m2[2,2];
{$ifdef SIMD}
 m1[2,3]:=0.0;
{$endif}
end;

procedure Matrix3x3Sub(var m1:TKraftMatrix3x3;const m2:TKraftMatrix3x3); {$ifdef caninline}inline;{$endif}
begin
 m1[0,0]:=m1[0,0]-m2[0,0];
 m1[0,1]:=m1[0,1]-m2[0,1];
 m1[0,2]:=m1[0,2]-m2[0,2];
{$ifdef SIMD}
 m1[0,3]:=0.0;
{$endif}
 m1[1,0]:=m1[1,0]-m2[1,0];
 m1[1,1]:=m1[1,1]-m2[1,1];
 m1[1,2]:=m1[1,2]-m2[1,2];
{$ifdef SIMD}
 m1[1,3]:=0.0;
{$endif}
 m1[2,0]:=m1[2,0]-m2[2,0];
 m1[2,1]:=m1[2,1]-m2[2,1];
 m1[2,2]:=m1[2,2]-m2[2,2];
{$ifdef SIMD}
 m1[2,3]:=0.0;
{$endif}
end;

procedure Matrix3x3Mul(var m1:TKraftMatrix3x3;const m2:TKraftMatrix3x3);
var t:TKraftMatrix3x3;
begin
 t[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[1,0])+(m1[0,2]*m2[2,0]);
 t[0,1]:=(m1[0,0]*m2[0,1])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[2,1]);
 t[0,2]:=(m1[0,0]*m2[0,2])+(m1[0,1]*m2[1,2])+(m1[0,2]*m2[2,2]);
{$ifdef SIMD}
 t[0,3]:=0.0;
{$endif}
 t[1,0]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[1,0])+(m1[1,2]*m2[2,0]);
 t[1,1]:=(m1[1,0]*m2[0,1])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[2,1]);
 t[1,2]:=(m1[1,0]*m2[0,2])+(m1[1,1]*m2[1,2])+(m1[1,2]*m2[2,2]);
{$ifdef SIMD}
 t[1,3]:=0.0;
{$endif}
 t[2,0]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[1,0])+(m1[2,2]*m2[2,0]);
 t[2,1]:=(m1[2,0]*m2[0,1])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[2,1]);
 t[2,2]:=(m1[2,0]*m2[0,2])+(m1[2,1]*m2[1,2])+(m1[2,2]*m2[2,2]);
{$ifdef SIMD}
 t[2,3]:=0.0;
{$endif}
 m1:=t;
end;
          
function Matrix3x3TermAdd(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m1[0,0]+m2[0,0];
 result[0,1]:=m1[0,1]+m2[0,1];
 result[0,2]:=m1[0,2]+m2[0,2];
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=m1[1,0]+m2[1,0];
 result[1,1]:=m1[1,1]+m2[1,1];
 result[1,2]:=m1[1,2]+m2[1,2];
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=m1[2,0]+m2[2,0];
 result[2,1]:=m1[2,1]+m2[2,1];
 result[2,2]:=m1[2,2]+m2[2,2];
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function Matrix3x3TermSub(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m1[0,0]-m2[0,0];
 result[0,1]:=m1[0,1]-m2[0,1];
 result[0,2]:=m1[0,2]-m2[0,2];
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=m1[1,0]-m2[1,0];
 result[1,1]:=m1[1,1]-m2[1,1];
 result[1,2]:=m1[1,2]-m2[1,2];
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=m1[2,0]-m2[2,0];
 result[2,1]:=m1[2,1]-m2[2,1];
 result[2,2]:=m1[2,2]-m2[2,2];
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function Matrix3x3TermMul(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3;
begin
 result[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[1,0])+(m1[0,2]*m2[2,0]);
 result[0,1]:=(m1[0,0]*m2[0,1])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[2,1]);
 result[0,2]:=(m1[0,0]*m2[0,2])+(m1[0,1]*m2[1,2])+(m1[0,2]*m2[2,2]);
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[1,0])+(m1[1,2]*m2[2,0]);
 result[1,1]:=(m1[1,0]*m2[0,1])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[2,1]);
 result[1,2]:=(m1[1,0]*m2[0,2])+(m1[1,1]*m2[1,2])+(m1[1,2]*m2[2,2]);
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[1,0])+(m1[2,2]*m2[2,0]);
 result[2,1]:=(m1[2,0]*m2[0,1])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[2,1]);
 result[2,2]:=(m1[2,0]*m2[0,2])+(m1[2,1]*m2[1,2])+(m1[2,2]*m2[2,2]);
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function Matrix3x3TermMulTranspose(const m1,m2:TKraftMatrix3x3):TKraftMatrix3x3;
begin
 result[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[0,1])+(m1[0,2]*m2[0,2]);
 result[0,1]:=(m1[0,0]*m2[1,0])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[1,2]);
 result[0,2]:=(m1[0,0]*m2[2,0])+(m1[0,1]*m2[2,1])+(m1[0,2]*m2[2,2]);
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[0,1])+(m1[1,2]*m2[0,2]);
 result[1,1]:=(m1[1,0]*m2[1,0])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[1,2]);
 result[1,2]:=(m1[1,0]*m2[2,0])+(m1[1,1]*m2[2,1])+(m1[1,2]*m2[2,2]);
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[0,1])+(m1[2,2]*m2[0,2]);
 result[2,1]:=(m1[2,0]*m2[1,0])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[1,2]);
 result[2,2]:=(m1[2,0]*m2[2,0])+(m1[2,1]*m2[2,1])+(m1[2,2]*m2[2,2]);
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

procedure Matrix3x3ScalarMul(var m:TKraftMatrix3x3;s:TKraftScalar); {$ifdef caninline}inline;{$endif}
begin
 m[0,0]:=m[0,0]*s;
 m[0,1]:=m[0,1]*s;
 m[0,2]:=m[0,2]*s;
{$ifdef SIMD}
 m[0,3]:=0.0;
{$endif}
 m[1,0]:=m[1,0]*s;
 m[1,1]:=m[1,1]*s;
 m[1,2]:=m[1,2]*s;
{$ifdef SIMD}
 m[1,3]:=0.0;
{$endif}
 m[2,0]:=m[2,0]*s;
 m[2,1]:=m[2,1]*s;
 m[2,2]:=m[2,2]*s;
{$ifdef SIMD}
 m[2,3]:=0.0;
{$endif}
end;

function Matrix3x3TermScalarMul(const m:TKraftMatrix3x3;s:TKraftScalar):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m[0,0]*s;
 result[0,1]:=m[0,1]*s;
 result[0,2]:=m[0,2]*s;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=m[1,0]*s;
 result[1,1]:=m[1,1]*s;
 result[1,2]:=m[1,2]*s;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=m[2,0]*s;
 result[2,1]:=m[2,1]*s;
 result[2,2]:=m[2,2]*s;
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

procedure Matrix3x3Transpose(var m:TKraftMatrix3x3); {$ifdef caninline}inline;{$endif}
var mt:TKraftMatrix3x3;
begin
 mt[0,0]:=m[0,0];
 mt[1,0]:=m[0,1];
 mt[2,0]:=m[0,2];
 mt[0,1]:=m[1,0];
 mt[1,1]:=m[1,1];
 mt[2,1]:=m[1,2];
 mt[0,2]:=m[2,0];
 mt[1,2]:=m[2,1];
 mt[2,2]:=m[2,2];
{$ifdef SIMD}
 mt[0,3]:=0.0;
 mt[1,3]:=0.0;
 mt[2,3]:=0.0;
{$endif}
 m:=mt;
end;

function Matrix3x3TermTranspose(const m:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m[0,0];
 result[1,0]:=m[0,1];
 result[2,0]:=m[0,2];
 result[0,1]:=m[1,0];
 result[1,1]:=m[1,1];
 result[2,1]:=m[1,2];
 result[0,2]:=m[2,0];
 result[1,2]:=m[2,1];
 result[2,2]:=m[2,2];
{$ifdef SIMD}
 result[0,3]:=0.0;
 result[1,3]:=0.0;
 result[2,3]:=0.0;
{$endif}
end;

function Matrix3x3Determinant(const m:TKraftMatrix3x3):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
 result:=(m[0,0]*((m[1,1]*m[2,2])-(m[2,1]*m[1,2])))-
         (m[0,1]*((m[1,0]*m[2,2])-(m[2,0]*m[1,2])))+
         (m[0,2]*((m[1,0]*m[2,1])-(m[2,0]*m[1,1])));
end;

function Matrix3x3EulerAngles(const m:TKraftMatrix3x3):TKraftVector3;
var v0,v1:TKraftVector3;
begin
 if abs((-1.0)-m[0,2])<EPSILON then begin
  result.x:=0.0;
  result.y:=pi*0.5;
  result.z:=ArcTan2(m[1,0],m[2,0]);
 end else if abs(1.0-m[0,2])<EPSILON then begin
  result.x:=0.0;
  result.y:=-(pi*0.5);
  result.z:=ArcTan2(-m[1,0],-m[2,0]);
 end else begin
  v0.x:=-ArcSin(m[0,2]);
  v1.x:=pi-v0.x;
  v0.y:=ArcTan2(m[1,2]/cos(v0.x),m[2,2]/cos(v0.x));
  v1.y:=ArcTan2(m[1,2]/cos(v1.x),m[2,2]/cos(v1.x));
  v0.z:=ArcTan2(m[0,1]/cos(v0.x),m[0,0]/cos(v0.x));
  v1.z:=ArcTan2(m[0,1]/cos(v1.x),m[0,0]/cos(v1.x));
  if Vector3LengthSquared(v0)<Vector3LengthSquared(v1) then begin
   result:=v0;
  end else begin
   result:=v1;
  end;
 end;
end;

procedure Matrix3x3SetColumn(var m:TKraftMatrix3x3;const c:longint;const v:TKraftVector3); {$ifdef caninline}inline;{$endif}
begin
 m[c,0]:=v.x;
 m[c,1]:=v.y;
 m[c,2]:=v.z;
end;

function Matrix3x3GetColumn(const m:TKraftMatrix3x3;const c:longint):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=m[c,0];
 result.y:=m[c,1];
 result.z:=m[c,2];
end;

procedure Matrix3x3SetRow(var m:TKraftMatrix3x3;const r:longint;const v:TKraftVector3); {$ifdef caninline}inline;{$endif}
begin
 m[0,r]:=v.x;
 m[1,r]:=v.y;
 m[2,r]:=v.z;
end;

function Matrix3x3GetRow(const m:TKraftMatrix3x3;const r:longint):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=m[0,r];
 result.y:=m[1,r];
 result.z:=m[2,r];
end;

function Matrix3x3Compare(const m1,m2:TKraftMatrix3x3):boolean;
var r,c:longint;
begin
 result:=true;
 for r:=0 to 2 do begin
  for c:=0 to 2 do begin
   if abs(m1[r,c]-m2[r,c])>EPSILON then begin
    result:=false;
    exit;
   end;
  end;
 end;
end;

function Matrix3x3Inverse(var mr:TKraftMatrix3x3;const ma:TKraftMatrix3x3):boolean;
var Determinant:TKraftScalar;
begin
 Determinant:=((ma[0,0]*((ma[1,1]*ma[2,2])-(ma[2,1]*ma[1,2])))-
               (ma[0,1]*((ma[1,0]*ma[2,2])-(ma[2,0]*ma[1,2]))))+
               (ma[0,2]*((ma[1,0]*ma[2,1])-(ma[2,0]*ma[1,1])));
 if abs(Determinant)<EPSILON then begin
  mr:=Matrix3x3Identity;
  result:=false;
 end else begin
  Determinant:=1.0/Determinant;
  mr[0,0]:=((ma[1,1]*ma[2,2])-(ma[2,1]*ma[1,2]))*Determinant;
  mr[0,1]:=((ma[0,2]*ma[2,1])-(ma[0,1]*ma[2,2]))*Determinant;
  mr[0,2]:=((ma[0,1]*ma[1,2])-(ma[0,2]*ma[1,1]))*Determinant;
{$ifdef SIMD}
  mr[0,3]:=0.0;
{$endif}
  mr[1,0]:=((ma[1,2]*ma[2,0])-(ma[1,0]*ma[2,2]))*Determinant;
  mr[1,1]:=((ma[0,0]*ma[2,2])-(ma[0,2]*ma[2,0]))*Determinant;
  mr[1,2]:=((ma[1,0]*ma[0,2])-(ma[0,0]*ma[1,2]))*Determinant;
{$ifdef SIMD}
  mr[1,3]:=0.0;
{$endif}
  mr[2,0]:=((ma[1,0]*ma[2,1])-(ma[2,0]*ma[1,1]))*Determinant;
  mr[2,1]:=((ma[2,0]*ma[0,1])-(ma[0,0]*ma[2,1]))*Determinant;
  mr[2,2]:=((ma[0,0]*ma[1,1])-(ma[1,0]*ma[0,1]))*Determinant;
{$ifdef SIMD}
  mr[2,3]:=0.0;
{$endif}
  result:=true;
 end;
end;

function Matrix3x3TermInverse(const m:TKraftMatrix3x3):TKraftMatrix3x3;
var Determinant:TKraftScalar;
begin
 Determinant:=((m[0,0]*((m[1,1]*m[2,2])-(m[2,1]*m[1,2])))-
               (m[0,1]*((m[1,0]*m[2,2])-(m[2,0]*m[1,2]))))+
               (m[0,2]*((m[1,0]*m[2,1])-(m[2,0]*m[1,1])));
 if abs(Determinant)<EPSILON then begin
  result:=Matrix3x3Identity;
 end else begin
  Determinant:=1.0/Determinant;
  result[0,0]:=((m[1,1]*m[2,2])-(m[2,1]*m[1,2]))*Determinant;
  result[0,1]:=((m[0,2]*m[2,1])-(m[0,1]*m[2,2]))*Determinant;
  result[0,2]:=((m[0,1]*m[1,2])-(m[0,2]*m[1,1]))*Determinant;
{$ifdef SIMD}
  result[0,3]:=0.0;
{$endif}
  result[1,0]:=((m[1,2]*m[2,0])-(m[1,0]*m[2,2]))*Determinant;
  result[1,1]:=((m[0,0]*m[2,2])-(m[0,2]*m[2,0]))*Determinant;
  result[1,2]:=((m[1,0]*m[0,2])-(m[0,0]*m[1,2]))*Determinant;
{$ifdef SIMD}
  result[1,3]:=0.0;
{$endif}
  result[2,0]:=((m[1,0]*m[2,1])-(m[2,0]*m[1,1]))*Determinant;
  result[2,1]:=((m[2,0]*m[0,1])-(m[0,0]*m[2,1]))*Determinant;
  result[2,2]:=((m[0,0]*m[1,1])-(m[1,0]*m[0,1]))*Determinant;
{$ifdef SIMD}
  result[2,3]:=0.0;
{$endif}
 end;
end;

procedure Matrix3x3OrthoNormalize(var m:TKraftMatrix3x3);
var x,y,z:TKraftVector3;
begin
 x.x:=m[0,0];
 x.y:=m[0,1];
 x.z:=m[0,2];
 Vector3NormalizeEx(x);
 y.x:=m[1,0];
 y.y:=m[1,1];
 y.z:=m[1,2];
 z:=Vector3NormEx(Vector3Cross(x,y));
 y:=Vector3NormEx(Vector3Cross(z,x));
 m[0,0]:=x.x;
 m[0,1]:=x.y;
 m[0,2]:=x.z;
{$ifdef SIMD}
 m[0,3]:=0.0;
{$endif}
 m[1,0]:=y.x;
 m[1,1]:=y.y;
 m[1,2]:=y.z;
{$ifdef SIMD}
 m[1,3]:=0.0;
{$endif}
 m[2,0]:=z.x;
 m[2,1]:=z.y;
 m[2,2]:=z.z;
{$ifdef SIMD}
 m[2,3]:=0.0;
{$endif}
end;

function Matrix3x3Slerp(const a,b:TKraftMatrix3x3;x:TKraftScalar):TKraftMatrix3x3;
//var ix:TKraftScalar;
begin
 if x<=0.0 then begin
  result:=a;
 end else if x>=1.0 then begin
  result:=b;
 end else begin
  result:=QuaternionToMatrix3x3(QuaternionSlerp(QuaternionFromMatrix3x3(a),QuaternionFromMatrix3x3(b),x));
 end;
end;

function Matrix3x3FromToRotation(const FromDirection,ToDirection:TKraftVector3):TKraftMatrix3x3;
var e,h,hvx,hvz,hvxy,hvxz,hvyz:TKraftScalar;
    x,u,v,c:TKraftVector3;
begin
 e:=(FromDirection.x*ToDirection.x)+(FromDirection.y*ToDirection.y)+(FromDirection.z*ToDirection.z);
 if abs(e)>(1.0-EPSILON) then begin
  x.x:=abs(FromDirection.x);
  x.y:=abs(FromDirection.y);
  x.z:=abs(FromDirection.z);
  if x.x<x.y then begin
   if x.x<x.z then begin
    x.x:=1.0;
    x.y:=0.0;
    x.z:=0.0;
   end else begin
    x.x:=0.0;
    x.y:=0.0;
    x.z:=1.0;
   end;
  end else begin
   if x.y<x.z then begin
    x.x:=0.0;
    x.y:=1.0;
    x.z:=0.0;
   end else begin
    x.x:=0.0;
    x.y:=0.0;
    x.z:=1.0;
   end;
  end;
  u.x:=x.x-FromDirection.x;
  u.y:=x.y-FromDirection.y;
  u.z:=x.z-FromDirection.z;
  v.x:=x.x-ToDirection.x;
  v.y:=x.y-ToDirection.y;
  v.z:=x.z-ToDirection.z;
  c.x:=2.0/(sqr(u.x)+sqr(u.y)+sqr(u.z));
  c.y:=2.0/(sqr(v.x)+sqr(v.y)+sqr(v.z));
  c.z:=c.x*c.y*((u.x*v.x)+(u.y*v.y)+(u.z*v.z));
  result[0,0]:=1.0+((c.z*(v.x*u.x))-((c.y*(v.x*v.x))+(c.x*(u.x*u.x))));
  result[0,1]:=(c.z*(v.x*u.y))-((c.y*(v.x*v.y))+(c.x*(u.x*u.y)));
  result[0,2]:=(c.z*(v.x*u.z))-((c.y*(v.x*v.z))+(c.x*(u.x*u.z)));
{$ifdef SIMD}
  result[0,3]:=0.0;
{$endif}
  result[1,0]:=(c.z*(v.y*u.x))-((c.y*(v.y*v.x))+(c.x*(u.y*u.x)));
  result[1,1]:=1.0+((c.z*(v.y*u.y))-((c.y*(v.y*v.y))+(c.x*(u.y*u.y))));
  result[1,2]:=(c.z*(v.y*u.z))-((c.y*(v.y*v.z))+(c.x*(u.y*u.z)));
{$ifdef SIMD}
  result[1,3]:=0.0;
{$endif}
  result[2,0]:=(c.z*(v.z*u.x))-((c.y*(v.z*v.x))+(c.x*(u.z*u.x)));
  result[2,1]:=(c.z*(v.z*u.y))-((c.y*(v.z*v.y))+(c.x*(u.z*u.y)));
  result[2,2]:=1.0+((c.z*(v.z*u.z))-((c.y*(v.z*v.z))+(c.x*(u.z*u.z))));
{$ifdef SIMD}
  result[2,3]:=0.0;
{$endif}
 end else begin
  v:=Vector3Cross(FromDirection,ToDirection);
  h:=1.0/(1.0+e);
  hvx:=h*v.x;
  hvz:=h*v.z;
  hvxy:=hvx*v.y;
  hvxz:=hvx*v.z;
  hvyz:=hvz*v.y;
  result[0,0]:=e+(hvx*v.x);
  result[0,1]:=hvxy-v.z;
  result[0,2]:=hvxz+v.y;
{$ifdef SIMD}
  result[0,3]:=0.0;
{$endif}
  result[1,0]:=hvxy+v.z;
  result[1,1]:=e+(h*sqr(v.y));
  result[1,2]:=hvyz-v.x;
{$ifdef SIMD}
  result[1,3]:=0.0;
{$endif}
  result[2,0]:=hvxz-v.y;
  result[2,1]:=hvyz+v.x;
  result[2,2]:=e+(hvz*v.z);
{$ifdef SIMD}
  result[2,3]:=0.0;
{$endif}
 end;
end;

function Matrix3x3Construct(const Forwards,Up:TKraftVector3):TKraftMatrix3x3;
var RightVector,UpVector,ForwardVector:TKraftVector3;
begin
 ForwardVector:=Vector3NormEx(Vector3Neg(Forwards));
 RightVector:=Vector3NormEx(Vector3Cross(Up,ForwardVector));
 UpVector:=Vector3NormEx(Vector3Cross(ForwardVector,RightVector));
 result[0,0]:=RightVector.x;
 result[0,1]:=RightVector.y;
 result[0,2]:=RightVector.z;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=UpVector.x;
 result[1,1]:=UpVector.y;
 result[1,2]:=UpVector.z;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=ForwardVector.x;
 result[2,1]:=ForwardVector.y;
 result[2,2]:=ForwardVector.z;
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function Matrix3x3OuterProduct(const u,v:TKraftVector3):TKraftMatrix3x3;
begin
 result[0,0]:=u.x*v.x;
 result[0,1]:=u.x*v.y;
 result[0,2]:=u.x*v.z;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=u.y*v.x;
 result[1,1]:=u.y*v.y;
 result[1,2]:=u.y*v.z;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=u.z*v.x;
 result[2,1]:=u.z*v.y;
 result[2,2]:=u.z*v.z;
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function Matrix4x4Set(m:TKraftMatrix3x3):TKraftMatrix4x4;
begin
 result[0,0]:=m[0,0];
 result[0,1]:=m[0,1];
 result[0,2]:=m[0,2];
 result[0,3]:=0;
 result[1,0]:=m[1,0];
 result[1,1]:=m[1,1];
 result[1,2]:=m[1,2];
 result[1,3]:=0;
 result[2,0]:=m[2,0];
 result[2,1]:=m[2,1];
 result[2,2]:=m[2,2];
 result[2,3]:=0;
 result[3,0]:=0;
 result[3,1]:=0;
 result[3,2]:=0;
 result[3,3]:=1;
end;

function Matrix4x4Rotation(m:TKraftMatrix4x4):TKraftMatrix4x4;
begin
 result[0,0]:=m[0,0];
 result[0,1]:=m[0,1];
 result[0,2]:=m[0,2];
 result[0,3]:=0;
 result[1,0]:=m[1,0];
 result[1,1]:=m[1,1];
 result[1,2]:=m[1,2];
 result[1,3]:=0;
 result[2,0]:=m[2,0];
 result[2,1]:=m[2,1];
 result[2,2]:=m[2,2];
 result[2,3]:=0;
 result[3,0]:=0;
 result[3,1]:=0;
 result[3,2]:=0;
 result[3,3]:=1;
end;

function Matrix4x4RotateX(Angle:TKraftScalar):TKraftMatrix4x4;
begin
 result:=Matrix4x4Identity;
 result[1,1]:=cos(Angle);
 result[2,2]:=result[1,1];
 result[1,2]:=sin(Angle);
 result[2,1]:=-result[1,2];
end;

function Matrix4x4RotateY(Angle:TKraftScalar):TKraftMatrix4x4;
begin
 result:=Matrix4x4Identity;
 result[0,0]:=cos(Angle);
 result[2,2]:=result[0,0];
 result[0,2]:=-sin(Angle);
 result[2,0]:=-result[0,2];
end;

function Matrix4x4RotateZ(Angle:TKraftScalar):TKraftMatrix4x4;
begin
 result:=Matrix4x4Identity;
 result[0,0]:=cos(Angle);
 result[1,1]:=result[0,0];
 result[0,1]:=sin(Angle);
 result[1,0]:=-result[0,1];
end;

function Matrix4x4Rotate(Angle:TKraftScalar;Axis:TKraftVector3):TKraftMatrix4x4; overload;
var m:TKraftMatrix4x4;
    CosinusAngle,SinusAngle:TKraftScalar;
begin
 m:=Matrix4x4Identity;
 CosinusAngle:=cos(Angle);
 SinusAngle:=sin(Angle);    
 m[0,0]:=CosinusAngle+((1-CosinusAngle)*Axis.x*Axis.x);
 m[1,0]:=((1-CosinusAngle)*Axis.x*Axis.y)-(Axis.z*SinusAngle);
 m[2,0]:=((1-CosinusAngle)*Axis.x*Axis.z)+(Axis.y*SinusAngle);
 m[0,1]:=((1-CosinusAngle)*Axis.x*Axis.z)+(Axis.z*SinusAngle);
 m[1,1]:=CosinusAngle+((1-CosinusAngle)*Axis.y*Axis.y);
 m[2,1]:=((1-CosinusAngle)*Axis.y*Axis.z)-(Axis.x*SinusAngle);
 m[0,2]:=((1-CosinusAngle)*Axis.x*Axis.z)-(Axis.y*SinusAngle);
 m[1,2]:=((1-CosinusAngle)*Axis.y*Axis.z)+(Axis.x*SinusAngle);
 m[2,2]:=CosinusAngle+((1-CosinusAngle)*Axis.z*Axis.z);
 result:=m;
end;

function Matrix4x4Translate(x,y,z:TKraftScalar):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4Identity;
 result[3,0]:=x;
 result[3,1]:=y;
 result[3,2]:=z;
end;

function Matrix4x4Translate(const v:TKraftVector3):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4Identity;
 result[3,0]:=v.x;
 result[3,1]:=v.y;
 result[3,2]:=v.z;
end;

function Matrix4x4Translate(const v:TKraftVector4):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4Identity;
 result[3,0]:=v.x;
 result[3,1]:=v.y;
 result[3,2]:=v.z;
end;

procedure Matrix4x4Translate(var m:TKraftMatrix4x4;const v:TKraftVector3); overload; {$ifdef caninline}inline;{$endif}
begin
 m[3,0]:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+m[3,0];
 m[3,1]:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+m[3,1];
 m[3,2]:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+m[3,2];
 m[3,3]:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+m[3,3];
end;

procedure Matrix4x4Translate(var m:TKraftMatrix4x4;const v:TKraftVector4); overload; {$ifdef caninline}inline;{$endif}
begin
 m[3,0]:=(m[0,0]*v.x)+(m[1,0]*v.y)+(m[2,0]*v.z)+(m[3,0]*v.w);
 m[3,1]:=(m[0,1]*v.x)+(m[1,1]*v.y)+(m[2,1]*v.z)+(m[3,1]*v.w);
 m[3,2]:=(m[0,2]*v.x)+(m[1,2]*v.y)+(m[2,2]*v.z)+(m[3,2]*v.w);
 m[3,3]:=(m[0,3]*v.x)+(m[1,3]*v.y)+(m[2,3]*v.z)+(m[3,3]*v.w);
end;

function Matrix4x4Scale(sx,sy,sz:TKraftScalar):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4Identity;
 result[0,0]:=sx;
 result[1,1]:=sy;
 result[2,2]:=sz;
end;

function Matrix4x4Scale(const s:TKraftVector3):TKraftMatrix4x4; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4Identity;
 result[0,0]:=s.x;
 result[1,1]:=s.y;
 result[2,2]:=s.z;
end;

procedure Matrix4x4Add(var m1:TKraftMatrix4x4;const m2:TKraftMatrix4x4); {$ifdef caninline}inline;{$endif}
begin
 m1[0,0]:=m1[0,0]+m2[0,0];
 m1[0,1]:=m1[0,1]+m2[0,1];
 m1[0,2]:=m1[0,2]+m2[0,2];
 m1[0,3]:=m1[0,3]+m2[0,3];
 m1[1,0]:=m1[1,0]+m2[1,0];
 m1[1,1]:=m1[1,1]+m2[1,1];
 m1[1,2]:=m1[1,2]+m2[1,2];
 m1[1,3]:=m1[1,3]+m2[1,3];
 m1[2,0]:=m1[2,0]+m2[2,0];
 m1[2,1]:=m1[2,1]+m2[2,1];
 m1[2,2]:=m1[2,2]+m2[2,2];
 m1[2,3]:=m1[2,3]+m2[2,3];
 m1[3,0]:=m1[3,0]+m2[3,0];
 m1[3,1]:=m1[3,1]+m2[3,1];
 m1[3,2]:=m1[3,2]+m2[3,2];
 m1[3,3]:=m1[3,3]+m2[3,3];
end;

procedure Matrix4x4Sub(var m1:TKraftMatrix4x4;const m2:TKraftMatrix4x4); {$ifdef caninline}inline;{$endif}
begin
 m1[0,0]:=m1[0,0]-m2[0,0];
 m1[0,1]:=m1[0,1]-m2[0,1];
 m1[0,2]:=m1[0,2]-m2[0,2];
 m1[0,3]:=m1[0,3]-m2[0,3];
 m1[1,0]:=m1[1,0]-m2[1,0];
 m1[1,1]:=m1[1,1]-m2[1,1];
 m1[1,2]:=m1[1,2]-m2[1,2];
 m1[1,3]:=m1[1,3]-m2[1,3];
 m1[2,0]:=m1[2,0]-m2[2,0];
 m1[2,1]:=m1[2,1]-m2[2,1];
 m1[2,2]:=m1[2,2]-m2[2,2];
 m1[2,3]:=m1[2,3]-m2[2,3];
 m1[3,0]:=m1[3,0]-m2[3,0];
 m1[3,1]:=m1[3,1]-m2[3,1];
 m1[3,2]:=m1[3,2]-m2[3,2];
 m1[3,3]:=m1[3,3]-m2[3,3];
end;

procedure Matrix4x4Mul(var m1:TKraftMatrix4x4;const m2:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}register;
asm
 movups xmm0,dqword ptr [m2+0]
 movups xmm1,dqword ptr [m2+16]
 movups xmm2,dqword ptr [m2+32]
 movups xmm3,dqword ptr [m2+48]

 movups xmm7,dqword ptr [m1+0]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [m1+0],xmm4

 movups xmm7,dqword ptr [m1+16]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [m1+16],xmm4

 movups xmm7,dqword ptr [m1+32]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [m1+32],xmm4

 movups xmm7,dqword ptr [m1+48]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [m1+48],xmm4

end;
{$else}
var t:TKraftMatrix4x4;
begin
 t[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[1,0])+(m1[0,2]*m2[2,0])+(m1[0,3]*m2[3,0]);
 t[0,1]:=(m1[0,0]*m2[0,1])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[2,1])+(m1[0,3]*m2[3,1]);
 t[0,2]:=(m1[0,0]*m2[0,2])+(m1[0,1]*m2[1,2])+(m1[0,2]*m2[2,2])+(m1[0,3]*m2[3,2]);
 t[0,3]:=(m1[0,0]*m2[0,3])+(m1[0,1]*m2[1,3])+(m1[0,2]*m2[2,3])+(m1[0,3]*m2[3,3]);
 t[1,0]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[1,0])+(m1[1,2]*m2[2,0])+(m1[1,3]*m2[3,0]);
 t[1,1]:=(m1[1,0]*m2[0,1])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[2,1])+(m1[1,3]*m2[3,1]);
 t[1,2]:=(m1[1,0]*m2[0,2])+(m1[1,1]*m2[1,2])+(m1[1,2]*m2[2,2])+(m1[1,3]*m2[3,2]);
 t[1,3]:=(m1[1,0]*m2[0,3])+(m1[1,1]*m2[1,3])+(m1[1,2]*m2[2,3])+(m1[1,3]*m2[3,3]);
 t[2,0]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[1,0])+(m1[2,2]*m2[2,0])+(m1[2,3]*m2[3,0]);
 t[2,1]:=(m1[2,0]*m2[0,1])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[2,1])+(m1[2,3]*m2[3,1]);
 t[2,2]:=(m1[2,0]*m2[0,2])+(m1[2,1]*m2[1,2])+(m1[2,2]*m2[2,2])+(m1[2,3]*m2[3,2]);
 t[2,3]:=(m1[2,0]*m2[0,3])+(m1[2,1]*m2[1,3])+(m1[2,2]*m2[2,3])+(m1[2,3]*m2[3,3]);
 t[3,0]:=(m1[3,0]*m2[0,0])+(m1[3,1]*m2[1,0])+(m1[3,2]*m2[2,0])+(m1[3,3]*m2[3,0]);
 t[3,1]:=(m1[3,0]*m2[0,1])+(m1[3,1]*m2[1,1])+(m1[3,2]*m2[2,1])+(m1[3,3]*m2[3,1]);
 t[3,2]:=(m1[3,0]*m2[0,2])+(m1[3,1]*m2[1,2])+(m1[3,2]*m2[2,2])+(m1[3,3]*m2[3,2]);
 t[3,3]:=(m1[3,0]*m2[0,3])+(m1[3,1]*m2[1,3])+(m1[3,2]*m2[2,3])+(m1[3,3]*m2[3,3]);
 m1:=t;
end;
{$endif}

procedure Matrix4x4Mul(var mr:TKraftMatrix4x4;const m1,m2:TKraftMatrix4x4); overload; {$ifdef CPU386ASMForSinglePrecision}register;
asm

 movups xmm0,dqword ptr [m2+0]
 movups xmm1,dqword ptr [m2+16]
 movups xmm2,dqword ptr [m2+32]
 movups xmm3,dqword ptr [m2+48]

 movups xmm7,dqword ptr [m1+0]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [mr+0],xmm4

 movups xmm7,dqword ptr [m1+16]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [mr+16],xmm4

 movups xmm7,dqword ptr [m1+32]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [mr+32],xmm4

 movups xmm7,dqword ptr [m1+48]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [mr+48],xmm4

end;
{$else}
begin
 mr[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[1,0])+(m1[0,2]*m2[2,0])+(m1[0,3]*m2[3,0]);
 mr[0,1]:=(m1[0,0]*m2[0,1])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[2,1])+(m1[0,3]*m2[3,1]);
 mr[0,2]:=(m1[0,0]*m2[0,2])+(m1[0,1]*m2[1,2])+(m1[0,2]*m2[2,2])+(m1[0,3]*m2[3,2]);
 mr[0,3]:=(m1[0,0]*m2[0,3])+(m1[0,1]*m2[1,3])+(m1[0,2]*m2[2,3])+(m1[0,3]*m2[3,3]);
 mr[1,0]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[1,0])+(m1[1,2]*m2[2,0])+(m1[1,3]*m2[3,0]);
 mr[1,1]:=(m1[1,0]*m2[0,1])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[2,1])+(m1[1,3]*m2[3,1]);
 mr[1,2]:=(m1[1,0]*m2[0,2])+(m1[1,1]*m2[1,2])+(m1[1,2]*m2[2,2])+(m1[1,3]*m2[3,2]);
 mr[1,3]:=(m1[1,0]*m2[0,3])+(m1[1,1]*m2[1,3])+(m1[1,2]*m2[2,3])+(m1[1,3]*m2[3,3]);
 mr[2,0]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[1,0])+(m1[2,2]*m2[2,0])+(m1[2,3]*m2[3,0]);
 mr[2,1]:=(m1[2,0]*m2[0,1])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[2,1])+(m1[2,3]*m2[3,1]);
 mr[2,2]:=(m1[2,0]*m2[0,2])+(m1[2,1]*m2[1,2])+(m1[2,2]*m2[2,2])+(m1[2,3]*m2[3,2]);
 mr[2,3]:=(m1[2,0]*m2[0,3])+(m1[2,1]*m2[1,3])+(m1[2,2]*m2[2,3])+(m1[2,3]*m2[3,3]);
 mr[3,0]:=(m1[3,0]*m2[0,0])+(m1[3,1]*m2[1,0])+(m1[3,2]*m2[2,0])+(m1[3,3]*m2[3,0]);
 mr[3,1]:=(m1[3,0]*m2[0,1])+(m1[3,1]*m2[1,1])+(m1[3,2]*m2[2,1])+(m1[3,3]*m2[3,1]);
 mr[3,2]:=(m1[3,0]*m2[0,2])+(m1[3,1]*m2[1,2])+(m1[3,2]*m2[2,2])+(m1[3,3]*m2[3,2]);
 mr[3,3]:=(m1[3,0]*m2[0,3])+(m1[3,1]*m2[1,3])+(m1[3,2]*m2[2,3])+(m1[3,3]*m2[3,3]);
end;
{$endif}

function Matrix4x4TermAdd(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m1[0,0]+m2[0,0];
 result[0,1]:=m1[0,1]+m2[0,1];
 result[0,2]:=m1[0,2]+m2[0,2];
 result[0,3]:=m1[0,3]+m2[0,3];
 result[1,0]:=m1[1,0]+m2[1,0];
 result[1,1]:=m1[1,1]+m2[1,1];
 result[1,2]:=m1[1,2]+m2[1,2];
 result[1,3]:=m1[1,3]+m2[1,3];
 result[2,0]:=m1[2,0]+m2[2,0];
 result[2,1]:=m1[2,1]+m2[2,1];
 result[2,2]:=m1[2,2]+m2[2,2];
 result[2,3]:=m1[2,3]+m2[2,3];
 result[3,0]:=m1[3,0]+m2[3,0];
 result[3,1]:=m1[3,1]+m2[3,1];
 result[3,2]:=m1[3,2]+m2[3,2];
 result[3,3]:=m1[3,3]+m2[3,3];
end;

function Matrix4x4TermSub(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=m1[0,0]-m2[0,0];
 result[0,1]:=m1[0,1]-m2[0,1];
 result[0,2]:=m1[0,2]-m2[0,2];
 result[0,3]:=m1[0,3]-m2[0,3];
 result[1,0]:=m1[1,0]-m2[1,0];
 result[1,1]:=m1[1,1]-m2[1,1];
 result[1,2]:=m1[1,2]-m2[1,2];
 result[1,3]:=m1[1,3]-m2[1,3];
 result[2,0]:=m1[2,0]-m2[2,0];
 result[2,1]:=m1[2,1]-m2[2,1];
 result[2,2]:=m1[2,2]-m2[2,2];
 result[2,3]:=m1[2,3]-m2[2,3];
 result[3,0]:=m1[3,0]-m2[3,0];
 result[3,1]:=m1[3,1]-m2[3,1];
 result[3,2]:=m1[3,2]-m2[3,2];
 result[3,3]:=m1[3,3]-m2[3,3];
end;

function Matrix4x4TermMul(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef CPU386ASMForSinglePrecision}register;
asm

 movups xmm0,dqword ptr [m2+0]
 movups xmm1,dqword ptr [m2+16]
 movups xmm2,dqword ptr [m2+32]
 movups xmm3,dqword ptr [m2+48]

 movups xmm7,dqword ptr [m1+0]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [result+0],xmm4

 movups xmm7,dqword ptr [m1+16]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [result+16],xmm4

 movups xmm7,dqword ptr [m1+32]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [result+32],xmm4

 movups xmm7,dqword ptr [m1+48]
 pshufd xmm4,xmm7,$00
 pshufd xmm5,xmm7,$55
 pshufd xmm6,xmm7,$aa
 pshufd xmm7,xmm7,$ff
 mulps xmm4,xmm0
 mulps xmm5,xmm1
 mulps xmm6,xmm2
 mulps xmm7,xmm3
 addps xmm4,xmm5
 addps xmm6,xmm7
 addps xmm4,xmm6
 movups dqword ptr [result+48],xmm4

end;
{$else}
begin
 result[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[1,0])+(m1[0,2]*m2[2,0])+(m1[0,3]*m2[3,0]);
 result[0,1]:=(m1[0,0]*m2[0,1])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[2,1])+(m1[0,3]*m2[3,1]);
 result[0,2]:=(m1[0,0]*m2[0,2])+(m1[0,1]*m2[1,2])+(m1[0,2]*m2[2,2])+(m1[0,3]*m2[3,2]);
 result[0,3]:=(m1[0,0]*m2[0,3])+(m1[0,1]*m2[1,3])+(m1[0,2]*m2[2,3])+(m1[0,3]*m2[3,3]);
 result[1,0]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[1,0])+(m1[1,2]*m2[2,0])+(m1[1,3]*m2[3,0]);
 result[1,1]:=(m1[1,0]*m2[0,1])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[2,1])+(m1[1,3]*m2[3,1]);
 result[1,2]:=(m1[1,0]*m2[0,2])+(m1[1,1]*m2[1,2])+(m1[1,2]*m2[2,2])+(m1[1,3]*m2[3,2]);
 result[1,3]:=(m1[1,0]*m2[0,3])+(m1[1,1]*m2[1,3])+(m1[1,2]*m2[2,3])+(m1[1,3]*m2[3,3]);
 result[2,0]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[1,0])+(m1[2,2]*m2[2,0])+(m1[2,3]*m2[3,0]);
 result[2,1]:=(m1[2,0]*m2[0,1])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[2,1])+(m1[2,3]*m2[3,1]);
 result[2,2]:=(m1[2,0]*m2[0,2])+(m1[2,1]*m2[1,2])+(m1[2,2]*m2[2,2])+(m1[2,3]*m2[3,2]);
 result[2,3]:=(m1[2,0]*m2[0,3])+(m1[2,1]*m2[1,3])+(m1[2,2]*m2[2,3])+(m1[2,3]*m2[3,3]);
 result[3,0]:=(m1[3,0]*m2[0,0])+(m1[3,1]*m2[1,0])+(m1[3,2]*m2[2,0])+(m1[3,3]*m2[3,0]);
 result[3,1]:=(m1[3,0]*m2[0,1])+(m1[3,1]*m2[1,1])+(m1[3,2]*m2[2,1])+(m1[3,3]*m2[3,1]);
 result[3,2]:=(m1[3,0]*m2[0,2])+(m1[3,1]*m2[1,2])+(m1[3,2]*m2[2,2])+(m1[3,3]*m2[3,2]);
 result[3,3]:=(m1[3,0]*m2[0,3])+(m1[3,1]*m2[1,3])+(m1[3,2]*m2[2,3])+(m1[3,3]*m2[3,3]);
end;
{$endif}

function Matrix4x4TermMulInverted(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4TermMul(m1,Matrix4x4TermInverse(m2));
end;

function Matrix4x4TermMulSimpleInverted(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
begin
 result:=Matrix4x4TermMul(m1,Matrix4x4TermSimpleInverse(m2));
end;

function Matrix4x4TermMulTranspose(const m1,m2:TKraftMatrix4x4):TKraftMatrix4x4;
begin
 result[0,0]:=(m1[0,0]*m2[0,0])+(m1[0,1]*m2[1,0])+(m1[0,2]*m2[2,0])+(m1[0,3]*m2[3,0]);
 result[1,0]:=(m1[0,0]*m2[0,1])+(m1[0,1]*m2[1,1])+(m1[0,2]*m2[2,1])+(m1[0,3]*m2[3,1]);
 result[2,0]:=(m1[0,0]*m2[0,2])+(m1[0,1]*m2[1,2])+(m1[0,2]*m2[2,2])+(m1[0,3]*m2[3,2]);
 result[3,0]:=(m1[0,0]*m2[0,3])+(m1[0,1]*m2[1,3])+(m1[0,2]*m2[2,3])+(m1[0,3]*m2[3,3]);
 result[0,1]:=(m1[1,0]*m2[0,0])+(m1[1,1]*m2[1,0])+(m1[1,2]*m2[2,0])+(m1[1,3]*m2[3,0]);
 result[1,1]:=(m1[1,0]*m2[0,1])+(m1[1,1]*m2[1,1])+(m1[1,2]*m2[2,1])+(m1[1,3]*m2[3,1]);
 result[2,1]:=(m1[1,0]*m2[0,2])+(m1[1,1]*m2[1,2])+(m1[1,2]*m2[2,2])+(m1[1,3]*m2[3,2]);
 result[3,1]:=(m1[1,0]*m2[0,3])+(m1[1,1]*m2[1,3])+(m1[1,2]*m2[2,3])+(m1[1,3]*m2[3,3]);
 result[0,2]:=(m1[2,0]*m2[0,0])+(m1[2,1]*m2[1,0])+(m1[2,2]*m2[2,0])+(m1[2,3]*m2[3,0]);
 result[1,2]:=(m1[2,0]*m2[0,1])+(m1[2,1]*m2[1,1])+(m1[2,2]*m2[2,1])+(m1[2,3]*m2[3,1]);
 result[2,2]:=(m1[2,0]*m2[0,2])+(m1[2,1]*m2[1,2])+(m1[2,2]*m2[2,2])+(m1[2,3]*m2[3,2]);
 result[3,2]:=(m1[2,0]*m2[0,3])+(m1[2,1]*m2[1,3])+(m1[2,2]*m2[2,3])+(m1[2,3]*m2[3,3]);
 result[0,3]:=(m1[3,0]*m2[0,0])+(m1[3,1]*m2[1,0])+(m1[3,2]*m2[2,0])+(m1[3,3]*m2[3,0]);
 result[1,3]:=(m1[3,0]*m2[0,1])+(m1[3,1]*m2[1,1])+(m1[3,2]*m2[2,1])+(m1[3,3]*m2[3,1]);
 result[2,3]:=(m1[3,0]*m2[0,2])+(m1[3,1]*m2[1,2])+(m1[3,2]*m2[2,2])+(m1[3,3]*m2[3,2]);
 result[3,3]:=(m1[3,0]*m2[0,3])+(m1[3,1]*m2[1,3])+(m1[3,2]*m2[2,3])+(m1[3,3]*m2[3,3]);
end;

function Matrix4x4Lerp(const a,b:TKraftMatrix4x4;x:TKraftScalar):TKraftMatrix4x4;
var ix:TKraftScalar;
begin
 if x<=0.0 then begin
  result:=a;
 end else if x>=1.0 then begin
  result:=b;
 end else begin
  ix:=1.0-x;
  result[0,0]:=(a[0,0]*ix)+(b[0,0]*x);
  result[0,1]:=(a[0,1]*ix)+(b[0,1]*x);
  result[0,2]:=(a[0,2]*ix)+(b[0,2]*x);
  result[0,3]:=(a[0,3]*ix)+(b[0,3]*x);
  result[1,0]:=(a[1,0]*ix)+(b[1,0]*x);
  result[1,1]:=(a[1,1]*ix)+(b[1,1]*x);
  result[1,2]:=(a[1,2]*ix)+(b[1,2]*x);
  result[1,3]:=(a[1,3]*ix)+(b[1,3]*x);
  result[2,0]:=(a[2,0]*ix)+(b[2,0]*x);
  result[2,1]:=(a[2,1]*ix)+(b[2,1]*x);
  result[2,2]:=(a[2,2]*ix)+(b[2,2]*x);
  result[2,3]:=(a[2,3]*ix)+(b[2,3]*x);
  result[3,0]:=(a[3,0]*ix)+(b[3,0]*x);
  result[3,1]:=(a[3,1]*ix)+(b[3,1]*x);
  result[3,2]:=(a[3,2]*ix)+(b[3,2]*x);
  result[3,3]:=(a[3,3]*ix)+(b[3,3]*x);
 end;
end;

function Matrix4x4Slerp(const a,b:TKraftMatrix4x4;x:TKraftScalar):TKraftMatrix4x4;
var ix:TKraftScalar;
    m:TKraftMatrix3x3;
begin
 if x<=0.0 then begin
  result:=a;
 end else if x>=1.0 then begin
  result:=b;
 end else begin
  m:=QuaternionToMatrix3x3(QuaternionSlerp(QuaternionFromMatrix4x4(a),QuaternionFromMatrix4x4(b),x));
  ix:=1.0-x;
  result[0,0]:=m[0,0];
  result[0,1]:=m[0,1];
  result[0,2]:=m[0,2];
  result[0,3]:=(a[0,3]*ix)+(b[0,3]*x);
  result[1,0]:=m[1,0];
  result[1,1]:=m[1,1];
  result[1,2]:=m[1,2];
  result[1,3]:=(a[1,3]*ix)+(b[1,3]*x);
  result[2,0]:=m[2,0];
  result[2,1]:=m[2,1];
  result[2,2]:=m[2,2];
  result[2,3]:=(a[2,3]*ix)+(b[2,3]*x);
  result[3,0]:=(a[3,0]*ix)+(b[3,0]*x);
  result[3,1]:=(a[3,1]*ix)+(b[3,1]*x);
  result[3,2]:=(a[3,2]*ix)+(b[3,2]*x);
  result[3,3]:=(a[3,3]*ix)+(b[3,3]*x);
 end;
end;

procedure Matrix4x4ScalarMul(var m:TKraftMatrix4x4;s:TKraftScalar); {$ifdef caninline}inline;{$endif}
begin
 m[0,0]:=m[0,0]*s;
 m[0,1]:=m[0,1]*s;
 m[0,2]:=m[0,2]*s;
 m[0,3]:=m[0,3]*s;
 m[1,0]:=m[1,0]*s;
 m[1,1]:=m[1,1]*s;
 m[1,2]:=m[1,2]*s;
 m[1,3]:=m[1,3]*s;
 m[2,0]:=m[2,0]*s;
 m[2,1]:=m[2,1]*s;
 m[2,2]:=m[2,2]*s;
 m[2,3]:=m[2,3]*s;
 m[3,0]:=m[3,0]*s;
 m[3,1]:=m[3,1]*s;
 m[3,2]:=m[3,2]*s;
 m[3,3]:=m[3,3]*s;
end;

procedure Matrix4x4Transpose(var m:TKraftMatrix4x4);
{$ifdef CPU386ASMForSinglePrecision}
asm
 movups xmm0,dqword ptr [m+0]
 movups xmm4,dqword ptr [m+16]
 movups xmm2,dqword ptr [m+32]
 movups xmm5,dqword ptr [m+48]
 movaps xmm1,xmm0
 movaps xmm3,xmm2
 unpcklps xmm0,xmm4
 unpckhps xmm1,xmm4
 unpcklps xmm2,xmm5
 unpckhps xmm3,xmm5
 movaps xmm4,xmm0
 movaps xmm6,xmm1
 shufps xmm0,xmm2,$44 // 01000100b
 shufps xmm4,xmm2,$ee // 11101110b
 shufps xmm1,xmm3,$44 // 01000100b
 shufps xmm6,xmm3,$ee // 11101110b
 movups dqword ptr [m+0],xmm0
 movups dqword ptr [m+16],xmm4
 movups dqword ptr [m+32],xmm1
 movups dqword ptr [m+48],xmm6
end;
{$else}
var mt:TKraftMatrix4x4;
begin
 mt[0,0]:=m[0,0];
 mt[0,1]:=m[1,0];
 mt[0,2]:=m[2,0];
 mt[0,3]:=m[3,0];
 mt[1,0]:=m[0,1];
 mt[1,1]:=m[1,1];
 mt[1,2]:=m[2,1];
 mt[1,3]:=m[3,1];
 mt[2,0]:=m[0,2];
 mt[2,1]:=m[1,2];
 mt[2,2]:=m[2,2];
 mt[2,3]:=m[3,2];
 mt[3,0]:=m[0,3];
 mt[3,1]:=m[1,3];
 mt[3,2]:=m[2,3];
 mt[3,3]:=m[3,3];
 m:=mt;
end;
{$endif}

function Matrix4x4TermTranspose(const m:TKraftMatrix4x4):TKraftMatrix4x4;
{$ifdef CPU386ASMForSinglePrecision}
asm
 movups xmm0,dqword ptr [m+0]
 movups xmm4,dqword ptr [m+16]
 movups xmm2,dqword ptr [m+32]
 movups xmm5,dqword ptr [m+48]
 movaps xmm1,xmm0
 movaps xmm3,xmm2
 unpcklps xmm0,xmm4
 unpckhps xmm1,xmm4
 unpcklps xmm2,xmm5
 unpckhps xmm3,xmm5
 movaps xmm4,xmm0
 movaps xmm6,xmm1
 shufps xmm0,xmm2,$44 // 01000100b
 shufps xmm4,xmm2,$ee // 11101110b
 shufps xmm1,xmm3,$44 // 01000100b
 shufps xmm6,xmm3,$ee // 11101110b
 movups dqword ptr [result+0],xmm0
 movups dqword ptr [result+16],xmm4
 movups dqword ptr [result+32],xmm1
 movups dqword ptr [result+48],xmm6
end;
{$else}
begin
 result[0,0]:=m[0,0];
 result[0,1]:=m[1,0];
 result[0,2]:=m[2,0];
 result[0,3]:=m[3,0];
 result[1,0]:=m[0,1];
 result[1,1]:=m[1,1];
 result[1,2]:=m[2,1];
 result[1,3]:=m[3,1];
 result[2,0]:=m[0,2];
 result[2,1]:=m[1,2];
 result[2,2]:=m[2,2];
 result[2,3]:=m[3,2];
 result[3,0]:=m[0,3];
 result[3,1]:=m[1,3];
 result[3,2]:=m[2,3];
 result[3,3]:=m[3,3];
end;
{$endif}

function Matrix4x4Determinant(const m:TKraftMatrix4x4):TKraftScalar;
{$ifdef CPU386ASMForSinglePrecision}
asm
 movups xmm0,dqword ptr [m+32]
 movups xmm1,dqword ptr [m+48]
 movups xmm2,dqword ptr [m+16]
 movaps xmm3,xmm0
 movaps xmm4,xmm0
 movaps xmm6,xmm1
 movaps xmm7,xmm2
 shufps xmm0,xmm0,$1b // 00011011b
 shufps xmm1,xmm1,$b1 // 10110001b
 shufps xmm2,xmm2,$4e // 01001110b
 shufps xmm7,xmm7,$39 // 00111001b
 mulps xmm0,xmm1
 shufps xmm3,xmm3,$7d // 01111101b
 shufps xmm6,xmm6,$0a // 00001010b
 movaps xmm5,xmm0
 shufps xmm0,xmm0,$4e // 01001110b
 shufps xmm4,xmm4,$0a // 00001010b
 shufps xmm1,xmm1,$28 // 00101000b
 subps xmm5,xmm0
 mulps xmm3,xmm6
 mulps xmm4,xmm1
 mulps xmm5,xmm2
 shufps xmm2,xmm2,$39 // 00111001b
 subps xmm3,xmm4
 movaps xmm0,xmm3
 shufps xmm0,xmm0,$39 // 00111001b
 mulps xmm3,xmm2
 mulps xmm0,xmm7
 addps xmm5,xmm3
 subps xmm5,xmm0
 movups xmm6,dqword ptr [m+0]
 mulps xmm5,xmm6
 movhlps xmm7,xmm5
 addps xmm5,xmm7
 movaps xmm6,xmm5
 shufps xmm6,xmm6,$01
 addss xmm5,xmm6
 movss dword ptr [result],xmm5
end;
{$else}
var inv:array[0..15] of TKraftScalar;
begin
 inv[0]:=(((m[1,1]*m[2,2]*m[3,3])-(m[1,1]*m[2,3]*m[3,2]))-(m[2,1]*m[1,2]*m[3,3])+(m[2,1]*m[1,3]*m[3,2])+(m[3,1]*m[1,2]*m[2,3]))-(m[3,1]*m[1,3]*m[2,2]);
 inv[4]:=((((-(m[1,0]*m[2,2]*m[3,3]))+(m[1,0]*m[2,3]*m[3,2])+(m[2,0]*m[1,2]*m[3,3]))-(m[2,0]*m[1,3]*m[3,2]))-(m[3,0]*m[1,2]*m[2,3]))+(m[3,0]*m[1,3]*m[2,2]);
 inv[8]:=((((m[1,0]*m[2,1]*m[3,3])-(m[1,0]*m[2,3]*m[3,1]))-(m[2,0]*m[1,1]*m[3,3]))+(m[2,0]*m[1,3]*m[3,1])+(m[3,0]*m[1,1]*m[2,3]))-(m[3,0]*m[1,3]*m[2,1]);
 inv[12]:=((((-(m[1,0]*m[2,1]*m[3,2]))+(m[1,0]*m[2,2]*m[3,1])+(m[2,0]*m[1,1]*m[3,2]))-(m[2,0]*m[1,2]*m[3,1]))-(m[3,0]*m[1,1]*m[2,2]))+(m[3,0]*m[1,2]*m[2,1]);
 inv[1]:=((((-(m[0,1]*m[2,2]*m[3,3]))+(m[0,1]*m[2,3]*m[3,2])+(m[2,1]*m[0,2]*m[3,3]))-(m[2,1]*m[0,3]*m[3,2]))-(m[3,1]*m[0,2]*m[2,3]))+(m[3,1]*m[0,3]*m[2,2]);
 inv[5]:=(((m[0,0]*m[2,2]*m[3,3])-(m[0,0]*m[2,3]*m[3,2]))-(m[2,0]*m[0,2]*m[3,3])+(m[2,0]*m[0,3]*m[3,2])+(m[3,0]*m[0,2]*m[2,3]))-(m[3,0]*m[0,3]*m[2,2]);
 inv[9]:=((((-(m[0,0]*m[2,1]*m[3,3]))+(m[0,0]*m[2,3]*m[3,1])+(m[2,0]*m[0,1]*m[3,3]))-(m[2,0]*m[0,3]*m[3,1]))-(m[3,0]*m[0,1]*m[2,3]))+(m[3,0]*m[0,3]*m[2,1]);
 inv[13]:=((((m[0,0]*m[2,1]*m[3,2])-(m[0,0]*m[2,2]*m[3,1]))-(m[2,0]*m[0,1]*m[3,2]))+(m[2,0]*m[0,2]*m[3,1])+(m[3,0]*m[0,1]*m[2,2]))-(m[3,0]*m[0,2]*m[2,1]);
 inv[2]:=((((m[0,1]*m[1,2]*m[3,3])-(m[0,1]*m[1,3]*m[3,2]))-(m[1,1]*m[0,2]*m[3,3]))+(m[1,1]*m[0,3]*m[3,2])+(m[3,1]*m[0,2]*m[1,3]))-(m[3,1]*m[0,3]*m[1,2]);
 inv[6]:=((((-(m[0,0]*m[1,2]*m[3,3]))+(m[0,0]*m[1,3]*m[3,2])+(m[1,0]*m[0,2]*m[3,3]))-(m[1,0]*m[0,3]*m[3,2]))-(m[3,0]*m[0,2]*m[1,3]))+(m[3,0]*m[0,3]*m[1,2]);
 inv[10]:=((((m[0,0]*m[1,1]*m[3,3])-(m[0,0]*m[1,3]*m[3,1]))-(m[1,0]*m[0,1]*m[3,3]))+(m[1,0]*m[0,3]*m[3,1])+(m[3,0]*m[0,1]*m[1,3]))-(m[3,0]*m[0,3]*m[1,1]);
 inv[14]:=((((-(m[0,0]*m[1,1]*m[3,2]))+(m[0,0]*m[1,2]*m[3,1])+(m[1,0]*m[0,1]*m[3,2]))-(m[1,0]*m[0,2]*m[3,1]))-(m[3,0]*m[0,1]*m[1,2]))+(m[3,0]*m[0,2]*m[1,1]);
 inv[3]:=((((-(m[0,1]*m[1,2]*m[2,3]))+(m[0,1]*m[1,3]*m[2,2])+(m[1,1]*m[0,2]*m[2,3]))-(m[1,1]*m[0,3]*m[2,2]))-(m[2,1]*m[0,2]*m[1,3]))+(m[2,1]*m[0,3]*m[1,2]);
 inv[7]:=((((m[0,0]*m[1,2]*m[2,3])-(m[0,0]*m[1,3]*m[2,2]))-(m[1,0]*m[0,2]*m[2,3]))+(m[1,0]*m[0,3]*m[2,2])+(m[2,0]*m[0,2]*m[1,3]))-(m[2,0]*m[0,3]*m[1,2]);
 inv[11]:=((((-(m[0,0]*m[1,1]*m[2,3]))+(m[0,0]*m[1,3]*m[2,1])+(m[1,0]*m[0,1]*m[2,3]))-(m[1,0]*m[0,3]*m[2,1]))-(m[2,0]*m[0,1]*m[1,3]))+(m[2,0]*m[0,3]*m[1,1]);
 inv[15]:=((((m[0,0]*m[1,1]*m[2,2])-(m[0,0]*m[1,2]*m[2,1]))-(m[1,0]*m[0,1]*m[2,2]))+(m[1,0]*m[0,2]*m[2,1])+(m[2,0]*m[0,1]*m[1,2]))-(m[2,0]*m[0,2]*m[1,1]);
 result:=(m[0,0]*inv[0])+(m[0,1]*inv[4])+(m[0,2]*inv[8])+(m[0,3]*inv[12]);
end;
{$endif}

procedure Matrix4x4SetColumn(var m:TKraftMatrix4x4;const c:longint;const v:TKraftVector4); {$ifdef caninline}inline;{$endif}
begin
 m[c,0]:=v.x;
 m[c,1]:=v.y;
 m[c,2]:=v.z;
 m[c,3]:=v.w;
end;

function Matrix4x4GetColumn(const m:TKraftMatrix4x4;const c:longint):TKraftVector4; {$ifdef caninline}inline;{$endif}
begin
 result.x:=m[c,0];
 result.y:=m[c,1];
 result.z:=m[c,2];
 result.w:=m[c,3];
end;

procedure Matrix4x4SetRow(var m:TKraftMatrix4x4;const r:longint;const v:TKraftVector4); {$ifdef caninline}inline;{$endif}
begin
 m[0,r]:=v.x;
 m[1,r]:=v.y;
 m[2,r]:=v.z;
 m[3,r]:=v.w;
end;

function Matrix4x4GetRow(const m:TKraftMatrix4x4;const r:longint):TKraftVector4; {$ifdef caninline}inline;{$endif}
begin
 result.x:=m[0,r];
 result.y:=m[1,r];
 result.z:=m[2,r];
 result.w:=m[3,r];
end;

function Matrix4x4Compare(const m1,m2:TKraftMatrix4x4):boolean;
var r,c:longint;
begin
 result:=true;
 for r:=0 to 3 do begin
  for c:=0 to 3 do begin
   if abs(m1[r,c]-m2[r,c])>EPSILON then begin
    result:=false;
    exit;
   end;
  end;
 end;
end;

procedure Matrix4x4Reflect(var mr:TKraftMatrix4x4;Plane:TKraftPlane);
begin
 PlaneNormalize(Plane);
 mr[0,0]:=1.0-(2.0*(Plane.Normal.x*Plane.Normal.x));
 mr[0,1]:=-(2.0*(Plane.Normal.x*Plane.Normal.y));
 mr[0,2]:=-(2.0*(Plane.Normal.x*Plane.Normal.z));
 mr[0,3]:=0.0;
 mr[1,0]:=-(2.0*(Plane.Normal.x*Plane.Normal.y));
 mr[1,1]:=1.0-(2.0*(Plane.Normal.y*Plane.Normal.y));
 mr[1,2]:=-(2.0*(Plane.Normal.y*Plane.Normal.z));
 mr[1,3]:=0.0;
 mr[2,0]:=-(2.0*(Plane.Normal.z*Plane.Normal.x));
 mr[2,1]:=-(2.0*(Plane.Normal.z*Plane.Normal.y));
 mr[2,2]:=1.0-(2.0*(Plane.Normal.z*Plane.Normal.z));
 mr[2,3]:=0.0;
 mr[3,0]:=-(2.0*(Plane.Distance*Plane.Normal.x));
 mr[3,1]:=-(2.0*(Plane.Distance*Plane.Normal.y));
 mr[3,2]:=-(2.0*(Plane.Distance*Plane.Normal.z));
 mr[3,3]:=1.0;
end;

function Matrix4x4TermReflect(Plane:TKraftPlane):TKraftMatrix4x4;
begin
 PlaneNormalize(Plane);
 result[0,0]:=1.0-(2.0*(Plane.Normal.x*Plane.Normal.x));
 result[0,1]:=-(2.0*(Plane.Normal.x*Plane.Normal.y));
 result[0,2]:=-(2.0*(Plane.Normal.x*Plane.Normal.z));
 result[0,3]:=0.0;
 result[1,0]:=-(2.0*(Plane.Normal.x*Plane.Normal.y));
 result[1,1]:=1.0-(2.0*(Plane.Normal.y*Plane.Normal.y));
 result[1,2]:=-(2.0*(Plane.Normal.y*Plane.Normal.z));
 result[1,3]:=0.0;
 result[2,0]:=-(2.0*(Plane.Normal.z*Plane.Normal.x));
 result[2,1]:=-(2.0*(Plane.Normal.z*Plane.Normal.y));
 result[2,2]:=1.0-(2.0*(Plane.Normal.z*Plane.Normal.z));
 result[2,3]:=0.0;
 result[3,0]:=-(2.0*(Plane.Distance*Plane.Normal.x));
 result[3,1]:=-(2.0*(Plane.Distance*Plane.Normal.y));
 result[3,2]:=-(2.0*(Plane.Distance*Plane.Normal.z));
 result[3,3]:=1.0;
end;

function Matrix4x4SimpleInverse(var mr:TKraftMatrix4x4;const ma:TKraftMatrix4x4):boolean; {$ifdef caninline}inline;{$endif}
begin
 mr[0,0]:=ma[0,0];
 mr[0,1]:=ma[1,0];
 mr[0,2]:=ma[2,0];
 mr[0,3]:=ma[0,3];
 mr[1,0]:=ma[0,1];
 mr[1,1]:=ma[1,1];
 mr[1,2]:=ma[2,1];
 mr[1,3]:=ma[1,3];
 mr[2,0]:=ma[0,2];
 mr[2,1]:=ma[1,2];
 mr[2,2]:=ma[2,2];
 mr[2,3]:=ma[2,3];
 mr[3,0]:=-Vector3Dot(PKraftVector3(pointer(@ma[3,0]))^,Vector3(ma[0,0],ma[0,1],ma[0,2]));
 mr[3,1]:=-Vector3Dot(PKraftVector3(pointer(@ma[3,0]))^,Vector3(ma[1,0],ma[1,1],ma[1,2]));
 mr[3,2]:=-Vector3Dot(PKraftVector3(pointer(@ma[3,0]))^,Vector3(ma[2,0],ma[2,1],ma[2,2]));
 mr[3,3]:=ma[3,3];
 result:=true;
end;

function Matrix4x4TermSimpleInverse(const ma:TKraftMatrix4x4):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=ma[0,0];
 result[0,1]:=ma[1,0];
 result[0,2]:=ma[2,0];
 result[0,3]:=ma[0,3];
 result[1,0]:=ma[0,1];
 result[1,1]:=ma[1,1];
 result[1,2]:=ma[2,1];
 result[1,3]:=ma[1,3];
 result[2,0]:=ma[0,2];
 result[2,1]:=ma[1,2];
 result[2,2]:=ma[2,2];
 result[2,3]:=ma[2,3];
 result[3,0]:=-Vector3Dot(PKraftVector3(pointer(@ma[3,0]))^,Vector3(ma[0,0],ma[0,1],ma[0,2]));
 result[3,1]:=-Vector3Dot(PKraftVector3(pointer(@ma[3,0]))^,Vector3(ma[1,0],ma[1,1],ma[1,2]));
 result[3,2]:=-Vector3Dot(PKraftVector3(pointer(@ma[3,0]))^,Vector3(ma[2,0],ma[2,1],ma[2,2]));
 result[3,3]:=ma[3,3];
end;

function Matrix4x4Inverse(var mr:TKraftMatrix4x4;const ma:TKraftMatrix4x4):boolean;
{$ifdef CPU386ASMForSinglePrecision}
asm
 mov ecx,esp
 and esp,$fffffff0
 sub esp,$b0
 movlps xmm2,qword ptr [ma+8]
 movlps xmm4,qword ptr [ma+40]
 movhps xmm2,qword ptr [ma+24]
 movhps xmm4,qword ptr [ma+56]
 movlps xmm3,qword ptr [ma+32]
 movlps xmm1,qword ptr [ma]
 movhps xmm3,qword ptr [ma+48]
 movhps xmm1,qword ptr [ma+16]
 movaps xmm5,xmm2
 shufps xmm5,xmm4,$88
 shufps xmm4,xmm2,$dd
 movaps xmm2,xmm4
 mulps xmm2,xmm5
 shufps xmm2,xmm2,$b1
 movaps xmm6,xmm2
 shufps xmm6,xmm6,$4e
 movaps xmm7,xmm3
 shufps xmm3,xmm1,$dd
 shufps xmm1,xmm7,$88
 movaps xmm7,xmm3
 mulps xmm3,xmm6
 mulps xmm6,xmm1
 movaps xmm0,xmm6
 movaps xmm6,xmm7
 mulps xmm7,xmm2
 mulps xmm2,xmm1
 subps xmm3,xmm7
 movaps xmm7,xmm6
 mulps xmm7,xmm5
 shufps xmm5,xmm5,$4e
 shufps xmm7,xmm7,$b1
 movaps dqword ptr [esp+16],xmm2
 movaps xmm2,xmm4
 mulps xmm2,xmm7
 addps xmm2,xmm3
 movaps xmm3,xmm7
 shufps xmm7,xmm7,$4e
 mulps xmm3,xmm1
 movaps dqword ptr [esp+32],xmm3
 movaps xmm3,xmm4
 mulps xmm3,xmm7
 mulps xmm7,xmm1
 subps xmm2,xmm3
 movaps xmm3,xmm6
 shufps xmm3,xmm3,$4e
 mulps xmm3,xmm4
 shufps xmm3,xmm3,$b1
 movaps dqword ptr [esp+48],xmm7
 movaps xmm7,xmm5
 mulps xmm5,xmm3
 addps xmm5,xmm2
 movaps xmm2,xmm3
 shufps xmm3,xmm3,$4e
 mulps xmm2,xmm1
 movaps dqword ptr [esp+64],xmm4
 movaps xmm4,xmm7
 mulps xmm7,xmm3
 mulps xmm3,xmm1
 subps xmm5,xmm7
 subps xmm3,xmm2
 movaps xmm2,xmm1
 mulps xmm1,xmm5
 shufps xmm3,xmm3,$4e
 movaps xmm7,xmm1
 shufps xmm1,xmm1,$4e
 movaps dqword ptr [esp],xmm5
 addps xmm1,xmm7
 movaps xmm5,xmm1
 shufps xmm1,xmm1,$b1
 addss xmm1,xmm5
 movaps xmm5,xmm6
 mulps xmm5,xmm2
 shufps xmm5,xmm5,$b1
 movaps xmm7,xmm5
 shufps xmm5,xmm5,$4e
 movaps dqword ptr [esp+80],xmm4
 movaps xmm4,dqword ptr [esp+64]
 movaps dqword ptr [esp+64],xmm6
 movaps xmm6,xmm4
 mulps xmm6,xmm7
 addps xmm6,xmm3
 movaps xmm3,xmm4
 mulps xmm3,xmm5
 subps xmm3,xmm6
 movaps xmm6,xmm4
 mulps xmm6,xmm2
 shufps xmm6,xmm6,$b1
 movaps dqword ptr [esp+112],xmm5
 movaps xmm5,dqword ptr [esp+64]
 movaps dqword ptr [esp+128],xmm7
 movaps xmm7,xmm6
 mulps xmm7,xmm5
 addps xmm7,xmm3
 movaps xmm3,xmm6
 shufps xmm3,xmm3,$4e
 movaps dqword ptr [esp+144],xmm4
 movaps xmm4,xmm5
 mulps xmm5,xmm3
 movaps dqword ptr [esp+160],xmm4
 movaps xmm4,xmm6
 movaps xmm6,xmm7
 subps xmm6,xmm5
 movaps xmm5,xmm0
 movaps xmm7,dqword ptr [esp+16]
 subps xmm5,xmm7
 shufps xmm5,xmm5,$4e
 movaps xmm7,dqword ptr [esp+80]
 mulps xmm4,xmm7
 mulps xmm3,xmm7
 subps xmm5,xmm4
 mulps xmm2,xmm7
 addps xmm3,xmm5
 shufps xmm2,xmm2,$b1
 movaps xmm4,xmm2
 shufps xmm4,xmm4,$4e
 movaps xmm5,dqword ptr [esp+144]
 movaps xmm0,xmm6
 movaps xmm6,xmm5
 mulps xmm5,xmm2
 mulps xmm6,xmm4
 addps xmm5,xmm3
 movaps xmm3,xmm4
 movaps xmm4,xmm5
 subps xmm4,xmm6
 movaps xmm5,dqword ptr [esp+48]
 movaps xmm6,dqword ptr [esp+32]
 subps xmm5,xmm6
 shufps xmm5,xmm5,$4e
 movaps xmm6,[esp+128]
 mulps xmm6,xmm7
 subps xmm6,xmm5
 movaps xmm5,dqword ptr [esp+112]
 mulps xmm7,xmm5
 subps xmm6,xmm7
 movaps xmm5,dqword ptr [esp+160]
 mulps xmm2,xmm5
 mulps xmm5,xmm3
 subps xmm6,xmm2
 movaps xmm2,xmm5
 addps xmm2,xmm6
 movaps xmm6,xmm0
 movaps xmm0,xmm1
 movaps xmm1,dqword ptr [esp]
 movaps xmm3,xmm0
 rcpss xmm5,xmm0
 mulss xmm0,xmm5
 mulss xmm0,xmm5
 addss xmm5,xmm5
 subss xmm5,xmm0
 movaps xmm0,xmm5
 addss xmm5,xmm5
 mulss xmm0,xmm0
 mulss xmm3,xmm0
 subss xmm5,xmm3
 shufps xmm5,xmm5,$00
 mulps xmm1,xmm5
 mulps xmm4,xmm5
 mulps xmm6,xmm5
 mulps xmm5,xmm2
 movups dqword ptr [mr+0],xmm1
 movups dqword ptr [mr+16],xmm4
 movups dqword ptr [mr+32],xmm6
 movups dqword ptr [mr+48],xmm5
 mov esp,ecx
 mov eax,1
end;
{$else}
var inv:array[0..15] of TKraftScalar;
    det:TKraftScalar;
begin
 inv[0]:=(((ma[1,1]*ma[2,2]*ma[3,3])-(ma[1,1]*ma[2,3]*ma[3,2]))-(ma[2,1]*ma[1,2]*ma[3,3])+(ma[2,1]*ma[1,3]*ma[3,2])+(ma[3,1]*ma[1,2]*ma[2,3]))-(ma[3,1]*ma[1,3]*ma[2,2]);
 inv[4]:=((((-(ma[1,0]*ma[2,2]*ma[3,3]))+(ma[1,0]*ma[2,3]*ma[3,2])+(ma[2,0]*ma[1,2]*ma[3,3]))-(ma[2,0]*ma[1,3]*ma[3,2]))-(ma[3,0]*ma[1,2]*ma[2,3]))+(ma[3,0]*ma[1,3]*ma[2,2]);
 inv[8]:=((((ma[1,0]*ma[2,1]*ma[3,3])-(ma[1,0]*ma[2,3]*ma[3,1]))-(ma[2,0]*ma[1,1]*ma[3,3]))+(ma[2,0]*ma[1,3]*ma[3,1])+(ma[3,0]*ma[1,1]*ma[2,3]))-(ma[3,0]*ma[1,3]*ma[2,1]);
 inv[12]:=((((-(ma[1,0]*ma[2,1]*ma[3,2]))+(ma[1,0]*ma[2,2]*ma[3,1])+(ma[2,0]*ma[1,1]*ma[3,2]))-(ma[2,0]*ma[1,2]*ma[3,1]))-(ma[3,0]*ma[1,1]*ma[2,2]))+(ma[3,0]*ma[1,2]*ma[2,1]);
 inv[1]:=((((-(ma[0,1]*ma[2,2]*ma[3,3]))+(ma[0,1]*ma[2,3]*ma[3,2])+(ma[2,1]*ma[0,2]*ma[3,3]))-(ma[2,1]*ma[0,3]*ma[3,2]))-(ma[3,1]*ma[0,2]*ma[2,3]))+(ma[3,1]*ma[0,3]*ma[2,2]);
 inv[5]:=(((ma[0,0]*ma[2,2]*ma[3,3])-(ma[0,0]*ma[2,3]*ma[3,2]))-(ma[2,0]*ma[0,2]*ma[3,3])+(ma[2,0]*ma[0,3]*ma[3,2])+(ma[3,0]*ma[0,2]*ma[2,3]))-(ma[3,0]*ma[0,3]*ma[2,2]);
 inv[9]:=((((-(ma[0,0]*ma[2,1]*ma[3,3]))+(ma[0,0]*ma[2,3]*ma[3,1])+(ma[2,0]*ma[0,1]*ma[3,3]))-(ma[2,0]*ma[0,3]*ma[3,1]))-(ma[3,0]*ma[0,1]*ma[2,3]))+(ma[3,0]*ma[0,3]*ma[2,1]);
 inv[13]:=((((ma[0,0]*ma[2,1]*ma[3,2])-(ma[0,0]*ma[2,2]*ma[3,1]))-(ma[2,0]*ma[0,1]*ma[3,2]))+(ma[2,0]*ma[0,2]*ma[3,1])+(ma[3,0]*ma[0,1]*ma[2,2]))-(ma[3,0]*ma[0,2]*ma[2,1]);
 inv[2]:=((((ma[0,1]*ma[1,2]*ma[3,3])-(ma[0,1]*ma[1,3]*ma[3,2]))-(ma[1,1]*ma[0,2]*ma[3,3]))+(ma[1,1]*ma[0,3]*ma[3,2])+(ma[3,1]*ma[0,2]*ma[1,3]))-(ma[3,1]*ma[0,3]*ma[1,2]);
 inv[6]:=((((-(ma[0,0]*ma[1,2]*ma[3,3]))+(ma[0,0]*ma[1,3]*ma[3,2])+(ma[1,0]*ma[0,2]*ma[3,3]))-(ma[1,0]*ma[0,3]*ma[3,2]))-(ma[3,0]*ma[0,2]*ma[1,3]))+(ma[3,0]*ma[0,3]*ma[1,2]);
 inv[10]:=((((ma[0,0]*ma[1,1]*ma[3,3])-(ma[0,0]*ma[1,3]*ma[3,1]))-(ma[1,0]*ma[0,1]*ma[3,3]))+(ma[1,0]*ma[0,3]*ma[3,1])+(ma[3,0]*ma[0,1]*ma[1,3]))-(ma[3,0]*ma[0,3]*ma[1,1]);
 inv[14]:=((((-(ma[0,0]*ma[1,1]*ma[3,2]))+(ma[0,0]*ma[1,2]*ma[3,1])+(ma[1,0]*ma[0,1]*ma[3,2]))-(ma[1,0]*ma[0,2]*ma[3,1]))-(ma[3,0]*ma[0,1]*ma[1,2]))+(ma[3,0]*ma[0,2]*ma[1,1]);
 inv[3]:=((((-(ma[0,1]*ma[1,2]*ma[2,3]))+(ma[0,1]*ma[1,3]*ma[2,2])+(ma[1,1]*ma[0,2]*ma[2,3]))-(ma[1,1]*ma[0,3]*ma[2,2]))-(ma[2,1]*ma[0,2]*ma[1,3]))+(ma[2,1]*ma[0,3]*ma[1,2]);
 inv[7]:=((((ma[0,0]*ma[1,2]*ma[2,3])-(ma[0,0]*ma[1,3]*ma[2,2]))-(ma[1,0]*ma[0,2]*ma[2,3]))+(ma[1,0]*ma[0,3]*ma[2,2])+(ma[2,0]*ma[0,2]*ma[1,3]))-(ma[2,0]*ma[0,3]*ma[1,2]);
 inv[11]:=((((-(ma[0,0]*ma[1,1]*ma[2,3]))+(ma[0,0]*ma[1,3]*ma[2,1])+(ma[1,0]*ma[0,1]*ma[2,3]))-(ma[1,0]*ma[0,3]*ma[2,1]))-(ma[2,0]*ma[0,1]*ma[1,3]))+(ma[2,0]*ma[0,3]*ma[1,1]);
 inv[15]:=((((ma[0,0]*ma[1,1]*ma[2,2])-(ma[0,0]*ma[1,2]*ma[2,1]))-(ma[1,0]*ma[0,1]*ma[2,2]))+(ma[1,0]*ma[0,2]*ma[2,1])+(ma[2,0]*ma[0,1]*ma[1,2]))-(ma[2,0]*ma[0,2]*ma[1,1]);
 det:=(ma[0,0]*inv[0])+(ma[0,1]*inv[4])+(ma[0,2]*inv[8])+(ma[0,3]*inv[12]);
 if det<>0.0 then begin
  det:=1.0/det;
  mr[0,0]:=inv[0]*det;
  mr[0,1]:=inv[1]*det;
  mr[0,2]:=inv[2]*det;
  mr[0,3]:=inv[3]*det;
  mr[1,0]:=inv[4]*det;
  mr[1,1]:=inv[5]*det;
  mr[1,2]:=inv[6]*det;
  mr[1,3]:=inv[7]*det;
  mr[2,0]:=inv[8]*det;
  mr[2,1]:=inv[9]*det;
  mr[2,2]:=inv[10]*det;
  mr[2,3]:=inv[11]*det;
  mr[3,0]:=inv[12]*det;
  mr[3,1]:=inv[13]*det;
  mr[3,2]:=inv[14]*det;
  mr[3,3]:=inv[15]*det;
  result:=true;
 end else begin
  result:=false;
 end;
end;
{$endif}

function Matrix4x4TermInverse(const ma:TKraftMatrix4x4):TKraftMatrix4x4;
{$ifdef CPU386ASMForSinglePrecision}
asm
 mov ecx,esp
 and esp,$fffffff0
 sub esp,$b0
 movlps xmm2,qword ptr [ma+8]
 movlps xmm4,qword ptr [ma+40]
 movhps xmm2,qword ptr [ma+24]
 movhps xmm4,qword ptr [ma+56]
 movlps xmm3,qword ptr [ma+32]
 movlps xmm1,qword ptr [ma]
 movhps xmm3,qword ptr [ma+48]
 movhps xmm1,qword ptr [ma+16]
 movaps xmm5,xmm2
 shufps xmm5,xmm4,$88
 shufps xmm4,xmm2,$dd
 movaps xmm2,xmm4
 mulps xmm2,xmm5
 shufps xmm2,xmm2,$b1
 movaps xmm6,xmm2
 shufps xmm6,xmm6,$4e
 movaps xmm7,xmm3
 shufps xmm3,xmm1,$dd
 shufps xmm1,xmm7,$88
 movaps xmm7,xmm3
 mulps xmm3,xmm6
 mulps xmm6,xmm1
 movaps xmm0,xmm6
 movaps xmm6,xmm7
 mulps xmm7,xmm2
 mulps xmm2,xmm1
 subps xmm3,xmm7
 movaps xmm7,xmm6
 mulps xmm7,xmm5
 shufps xmm5,xmm5,$4e
 shufps xmm7,xmm7,$b1
 movaps dqword ptr [esp+16],xmm2
 movaps xmm2,xmm4
 mulps xmm2,xmm7
 addps xmm2,xmm3
 movaps xmm3,xmm7
 shufps xmm7,xmm7,$4e
 mulps xmm3,xmm1
 movaps dqword ptr [esp+32],xmm3
 movaps xmm3,xmm4
 mulps xmm3,xmm7
 mulps xmm7,xmm1
 subps xmm2,xmm3
 movaps xmm3,xmm6
 shufps xmm3,xmm3,$4e
 mulps xmm3,xmm4
 shufps xmm3,xmm3,$b1
 movaps dqword ptr [esp+48],xmm7
 movaps xmm7,xmm5
 mulps xmm5,xmm3
 addps xmm5,xmm2
 movaps xmm2,xmm3
 shufps xmm3,xmm3,$4e
 mulps xmm2,xmm1
 movaps dqword ptr [esp+64],xmm4
 movaps xmm4,xmm7
 mulps xmm7,xmm3
 mulps xmm3,xmm1
 subps xmm5,xmm7
 subps xmm3,xmm2
 movaps xmm2,xmm1
 mulps xmm1,xmm5
 shufps xmm3,xmm3,$4e
 movaps xmm7,xmm1
 shufps xmm1,xmm1,$4e
 movaps dqword ptr [esp],xmm5
 addps xmm1,xmm7
 movaps xmm5,xmm1
 shufps xmm1,xmm1,$b1
 addss xmm1,xmm5
 movaps xmm5,xmm6
 mulps xmm5,xmm2
 shufps xmm5,xmm5,$b1
 movaps xmm7,xmm5
 shufps xmm5,xmm5,$4e
 movaps dqword ptr [esp+80],xmm4
 movaps xmm4,dqword ptr [esp+64]
 movaps dqword ptr [esp+64],xmm6
 movaps xmm6,xmm4
 mulps xmm6,xmm7
 addps xmm6,xmm3
 movaps xmm3,xmm4
 mulps xmm3,xmm5
 subps xmm3,xmm6
 movaps xmm6,xmm4
 mulps xmm6,xmm2
 shufps xmm6,xmm6,$b1
 movaps dqword ptr [esp+112],xmm5
 movaps xmm5,dqword ptr [esp+64]
 movaps dqword ptr [esp+128],xmm7
 movaps xmm7,xmm6
 mulps xmm7,xmm5
 addps xmm7,xmm3
 movaps xmm3,xmm6
 shufps xmm3,xmm3,$4e
 movaps dqword ptr [esp+144],xmm4
 movaps xmm4,xmm5
 mulps xmm5,xmm3
 movaps dqword ptr [esp+160],xmm4
 movaps xmm4,xmm6
 movaps xmm6,xmm7
 subps xmm6,xmm5
 movaps xmm5,xmm0
 movaps xmm7,dqword ptr [esp+16]
 subps xmm5,xmm7
 shufps xmm5,xmm5,$4e
 movaps xmm7,dqword ptr [esp+80]
 mulps xmm4,xmm7
 mulps xmm3,xmm7
 subps xmm5,xmm4
 mulps xmm2,xmm7
 addps xmm3,xmm5
 shufps xmm2,xmm2,$b1
 movaps xmm4,xmm2
 shufps xmm4,xmm4,$4e
 movaps xmm5,dqword ptr [esp+144]
 movaps xmm0,xmm6
 movaps xmm6,xmm5
 mulps xmm5,xmm2
 mulps xmm6,xmm4
 addps xmm5,xmm3
 movaps xmm3,xmm4
 movaps xmm4,xmm5
 subps xmm4,xmm6
 movaps xmm5,dqword ptr [esp+48]
 movaps xmm6,dqword ptr [esp+32]
 subps xmm5,xmm6
 shufps xmm5,xmm5,$4e
 movaps xmm6,[esp+128]
 mulps xmm6,xmm7
 subps xmm6,xmm5
 movaps xmm5,dqword ptr [esp+112]
 mulps xmm7,xmm5
 subps xmm6,xmm7
 movaps xmm5,dqword ptr [esp+160]
 mulps xmm2,xmm5
 mulps xmm5,xmm3
 subps xmm6,xmm2
 movaps xmm2,xmm5
 addps xmm2,xmm6
 movaps xmm6,xmm0
 movaps xmm0,xmm1
 movaps xmm1,dqword ptr [esp]
 movaps xmm3,xmm0
 rcpss xmm5,xmm0
 mulss xmm0,xmm5
 mulss xmm0,xmm5
 addss xmm5,xmm5
 subss xmm5,xmm0
 movaps xmm0,xmm5
 addss xmm5,xmm5
 mulss xmm0,xmm0
 mulss xmm3,xmm0
 subss xmm5,xmm3
 shufps xmm5,xmm5,$00
 mulps xmm1,xmm5
 mulps xmm4,xmm5
 mulps xmm6,xmm5
 mulps xmm5,xmm2
 movups dqword ptr [result+0],xmm1
 movups dqword ptr [result+16],xmm4
 movups dqword ptr [result+32],xmm6
 movups dqword ptr [result+48],xmm5
 mov esp,ecx
end;
{$else}
var inv:array[0..15] of TKraftScalar;
    det:TKraftScalar;
begin
 inv[0]:=(((ma[1,1]*ma[2,2]*ma[3,3])-(ma[1,1]*ma[2,3]*ma[3,2]))-(ma[2,1]*ma[1,2]*ma[3,3])+(ma[2,1]*ma[1,3]*ma[3,2])+(ma[3,1]*ma[1,2]*ma[2,3]))-(ma[3,1]*ma[1,3]*ma[2,2]);
 inv[4]:=((((-(ma[1,0]*ma[2,2]*ma[3,3]))+(ma[1,0]*ma[2,3]*ma[3,2])+(ma[2,0]*ma[1,2]*ma[3,3]))-(ma[2,0]*ma[1,3]*ma[3,2]))-(ma[3,0]*ma[1,2]*ma[2,3]))+(ma[3,0]*ma[1,3]*ma[2,2]);
 inv[8]:=((((ma[1,0]*ma[2,1]*ma[3,3])-(ma[1,0]*ma[2,3]*ma[3,1]))-(ma[2,0]*ma[1,1]*ma[3,3]))+(ma[2,0]*ma[1,3]*ma[3,1])+(ma[3,0]*ma[1,1]*ma[2,3]))-(ma[3,0]*ma[1,3]*ma[2,1]);
 inv[12]:=((((-(ma[1,0]*ma[2,1]*ma[3,2]))+(ma[1,0]*ma[2,2]*ma[3,1])+(ma[2,0]*ma[1,1]*ma[3,2]))-(ma[2,0]*ma[1,2]*ma[3,1]))-(ma[3,0]*ma[1,1]*ma[2,2]))+(ma[3,0]*ma[1,2]*ma[2,1]);
 inv[1]:=((((-(ma[0,1]*ma[2,2]*ma[3,3]))+(ma[0,1]*ma[2,3]*ma[3,2])+(ma[2,1]*ma[0,2]*ma[3,3]))-(ma[2,1]*ma[0,3]*ma[3,2]))-(ma[3,1]*ma[0,2]*ma[2,3]))+(ma[3,1]*ma[0,3]*ma[2,2]);
 inv[5]:=(((ma[0,0]*ma[2,2]*ma[3,3])-(ma[0,0]*ma[2,3]*ma[3,2]))-(ma[2,0]*ma[0,2]*ma[3,3])+(ma[2,0]*ma[0,3]*ma[3,2])+(ma[3,0]*ma[0,2]*ma[2,3]))-(ma[3,0]*ma[0,3]*ma[2,2]);
 inv[9]:=((((-(ma[0,0]*ma[2,1]*ma[3,3]))+(ma[0,0]*ma[2,3]*ma[3,1])+(ma[2,0]*ma[0,1]*ma[3,3]))-(ma[2,0]*ma[0,3]*ma[3,1]))-(ma[3,0]*ma[0,1]*ma[2,3]))+(ma[3,0]*ma[0,3]*ma[2,1]);
 inv[13]:=((((ma[0,0]*ma[2,1]*ma[3,2])-(ma[0,0]*ma[2,2]*ma[3,1]))-(ma[2,0]*ma[0,1]*ma[3,2]))+(ma[2,0]*ma[0,2]*ma[3,1])+(ma[3,0]*ma[0,1]*ma[2,2]))-(ma[3,0]*ma[0,2]*ma[2,1]);
 inv[2]:=((((ma[0,1]*ma[1,2]*ma[3,3])-(ma[0,1]*ma[1,3]*ma[3,2]))-(ma[1,1]*ma[0,2]*ma[3,3]))+(ma[1,1]*ma[0,3]*ma[3,2])+(ma[3,1]*ma[0,2]*ma[1,3]))-(ma[3,1]*ma[0,3]*ma[1,2]);
 inv[6]:=((((-(ma[0,0]*ma[1,2]*ma[3,3]))+(ma[0,0]*ma[1,3]*ma[3,2])+(ma[1,0]*ma[0,2]*ma[3,3]))-(ma[1,0]*ma[0,3]*ma[3,2]))-(ma[3,0]*ma[0,2]*ma[1,3]))+(ma[3,0]*ma[0,3]*ma[1,2]);
 inv[10]:=((((ma[0,0]*ma[1,1]*ma[3,3])-(ma[0,0]*ma[1,3]*ma[3,1]))-(ma[1,0]*ma[0,1]*ma[3,3]))+(ma[1,0]*ma[0,3]*ma[3,1])+(ma[3,0]*ma[0,1]*ma[1,3]))-(ma[3,0]*ma[0,3]*ma[1,1]);
 inv[14]:=((((-(ma[0,0]*ma[1,1]*ma[3,2]))+(ma[0,0]*ma[1,2]*ma[3,1])+(ma[1,0]*ma[0,1]*ma[3,2]))-(ma[1,0]*ma[0,2]*ma[3,1]))-(ma[3,0]*ma[0,1]*ma[1,2]))+(ma[3,0]*ma[0,2]*ma[1,1]);
 inv[3]:=((((-(ma[0,1]*ma[1,2]*ma[2,3]))+(ma[0,1]*ma[1,3]*ma[2,2])+(ma[1,1]*ma[0,2]*ma[2,3]))-(ma[1,1]*ma[0,3]*ma[2,2]))-(ma[2,1]*ma[0,2]*ma[1,3]))+(ma[2,1]*ma[0,3]*ma[1,2]);
 inv[7]:=((((ma[0,0]*ma[1,2]*ma[2,3])-(ma[0,0]*ma[1,3]*ma[2,2]))-(ma[1,0]*ma[0,2]*ma[2,3]))+(ma[1,0]*ma[0,3]*ma[2,2])+(ma[2,0]*ma[0,2]*ma[1,3]))-(ma[2,0]*ma[0,3]*ma[1,2]);
 inv[11]:=((((-(ma[0,0]*ma[1,1]*ma[2,3]))+(ma[0,0]*ma[1,3]*ma[2,1])+(ma[1,0]*ma[0,1]*ma[2,3]))-(ma[1,0]*ma[0,3]*ma[2,1]))-(ma[2,0]*ma[0,1]*ma[1,3]))+(ma[2,0]*ma[0,3]*ma[1,1]);
 inv[15]:=((((ma[0,0]*ma[1,1]*ma[2,2])-(ma[0,0]*ma[1,2]*ma[2,1]))-(ma[1,0]*ma[0,1]*ma[2,2]))+(ma[1,0]*ma[0,2]*ma[2,1])+(ma[2,0]*ma[0,1]*ma[1,2]))-(ma[2,0]*ma[0,2]*ma[1,1]);
 det:=(ma[0,0]*inv[0])+(ma[0,1]*inv[4])+(ma[0,2]*inv[8])+(ma[0,3]*inv[12]);
 if det<>0.0 then begin
  det:=1.0/det;
  result[0,0]:=inv[0]*det;
  result[0,1]:=inv[1]*det;
  result[0,2]:=inv[2]*det;
  result[0,3]:=inv[3]*det;
  result[1,0]:=inv[4]*det;
  result[1,1]:=inv[5]*det;
  result[1,2]:=inv[6]*det;
  result[1,3]:=inv[7]*det;
  result[2,0]:=inv[8]*det;
  result[2,1]:=inv[9]*det;
  result[2,2]:=inv[10]*det;
  result[2,3]:=inv[11]*det;
  result[3,0]:=inv[12]*det;
  result[3,1]:=inv[13]*det;
  result[3,2]:=inv[14]*det;
  result[3,3]:=inv[15]*det;
 end else begin
  result:=ma;
 end;
end;
{$endif}

function Matrix4x4InverseOld(var mr:TKraftMatrix4x4;const ma:TKraftMatrix4x4):boolean;
var Det,IDet:TKraftScalar;
begin
 Det:=(ma[0,0]*ma[1,1]*ma[2,2])+
      (ma[1,0]*ma[2,1]*ma[0,2])+
      (ma[2,0]*ma[0,1]*ma[1,2])-
      (ma[2,0]*ma[1,1]*ma[0,2])-
      (ma[1,0]*ma[0,1]*ma[2,2])-
      (ma[0,0]*ma[2,1]*ma[1,2]);
 if abs(Det)<EPSILON then begin
  mr:=Matrix4x4Identity;
  result:=false;
 end else begin
  IDet:=1/Det;
  mr[0,0]:=(ma[1,1]*ma[2,2]-ma[2,1]*ma[1,2])*IDet;
  mr[0,1]:=-(ma[0,1]*ma[2,2]-ma[2,1]*ma[0,2])*IDet;
  mr[0,2]:=(ma[0,1]*ma[1,2]-ma[1,1]*ma[0,2])*IDet;
  mr[0,3]:=0.0;
  mr[1,0]:=-(ma[1,0]*ma[2,2]-ma[2,0]*ma[1,2])*IDet;
  mr[1,1]:=(ma[0,0]*ma[2,2]-ma[2,0]*ma[0,2])*IDet;
  mr[1,2]:=-(ma[0,0]*ma[1,2]-ma[1,0]*ma[0,2])*IDet;
  mr[1,3]:=0.0;
  mr[2,0]:=(ma[1,0]*ma[2,1]-ma[2,0]*ma[1,1])*IDet;
  mr[2,1]:=-(ma[0,0]*ma[2,1]-ma[2,0]*ma[0,1])*IDet;
  mr[2,2]:=(ma[0,0]*ma[1,1]-ma[1,0]*ma[0,1])*IDet;
  mr[2,3]:=0.0;
  mr[3,0]:=-(ma[3,0]*mr[0,0]+ma[3,1]*mr[1,0]+ma[3,2]*mr[2,0]);
  mr[3,1]:=-(ma[3,0]*mr[0,1]+ma[3,1]*mr[1,1]+ma[3,2]*mr[2,1]);
  mr[3,2]:=-(ma[3,0]*mr[0,2]+ma[3,1]*mr[1,2]+ma[3,2]*mr[2,2]);
  mr[3,3]:=1.0;
  result:=true;
 end;
end;

function Matrix4x4TermInverseOld(const ma:TKraftMatrix4x4):TKraftMatrix4x4;
var Det,IDet:TKraftScalar;
begin
 Det:=((((ma[0,0]*ma[1,1]*ma[2,2])+
         (ma[1,0]*ma[2,1]*ma[0,2])+
         (ma[2,0]*ma[0,1]*ma[1,2]))-
        (ma[2,0]*ma[1,1]*ma[0,2]))-
       (ma[1,0]*ma[0,1]*ma[2,2]))-
      (ma[0,0]*ma[2,1]*ma[1,2]);
 if abs(Det)<EPSILON then begin
  result:=Matrix4x4Identity;
 end else begin
  IDet:=1/Det;
  result[0,0]:=(ma[1,1]*ma[2,2]-ma[2,1]*ma[1,2])*IDet;
  result[0,1]:=-(ma[0,1]*ma[2,2]-ma[2,1]*ma[0,2])*IDet;
  result[0,2]:=(ma[0,1]*ma[1,2]-ma[1,1]*ma[0,2])*IDet;
  result[0,3]:=0.0;
  result[1,0]:=-(ma[1,0]*ma[2,2]-ma[2,0]*ma[1,2])*IDet;
  result[1,1]:=(ma[0,0]*ma[2,2]-ma[2,0]*ma[0,2])*IDet;
  result[1,2]:=-(ma[0,0]*ma[1,2]-ma[1,0]*ma[0,2])*IDet;
  result[1,3]:=0.0;
  result[2,0]:=(ma[1,0]*ma[2,1]-ma[2,0]*ma[1,1])*IDet;
  result[2,1]:=-(ma[0,0]*ma[2,1]-ma[2,0]*ma[0,1])*IDet;
  result[2,2]:=(ma[0,0]*ma[1,1]-ma[1,0]*ma[0,1])*IDet;
  result[2,3]:=0.0;
  result[3,0]:=-(ma[3,0]*result[0,0]+ma[3,1]*result[1,0]+ma[3,2]*result[2,0]);
  result[3,1]:=-(ma[3,0]*result[0,1]+ma[3,1]*result[1,1]+ma[3,2]*result[2,1]);
  result[3,2]:=-(ma[3,0]*result[0,2]+ma[3,1]*result[1,2]+ma[3,2]*result[2,2]);
  result[3,3]:=1.0;
 end;
end;

function Matrix4x4GetSubMatrix3x3(const m:TKraftMatrix4x4;i,j:longint):TKraftMatrix3x3;
var di,dj,si,sj:longint;
begin
 for di:=0 to 2 do begin
  for dj:=0 to 2 do begin
   if di>=i then begin
    si:=di+1;
   end else begin
    si:=di;
   end;
   if dj>=j then begin
    sj:=dj+1;
   end else begin
    sj:=dj;
   end;
   result[di,dj]:=m[si,sj];
  end;
 end;
{$ifdef SIMD}
 result[0,3]:=0.0;
 result[1,3]:=0.0;
 result[2,3]:=0.0;
{$endif}
end;

function Matrix4x4Frustum(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
var rml,tmb,fmn:TKraftScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 result[0,0]:=(zNear*2.0)/rml;
 result[0,1]:=0.0;
 result[0,2]:=0.0;
 result[0,3]:=0.0;
 result[1,0]:=0.0;
 result[1,1]:=(zNear*2.0)/tmb;
 result[1,2]:=0.0;
 result[1,3]:=0.0;
 result[2,0]:=(Right+Left)/rml;
 result[2,1]:=(Top+Bottom)/tmb;
 result[2,2]:=(-(zFar+zNear))/fmn;
 result[2,3]:=-1.0;
 result[3,0]:=0.0;
 result[3,1]:=0.0;
 result[3,2]:=(-((zFar*zNear)*2.0))/fmn;
 result[3,3]:=0.0;
end;

function Matrix4x4Ortho(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
var rml,tmb,fmn:TKraftScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 result[0,0]:=2.0/rml;
 result[0,1]:=0.0;
 result[0,2]:=0.0;
 result[0,3]:=0.0;
 result[1,0]:=0.0;
 result[1,1]:=2.0/tmb;
 result[1,2]:=0.0;
 result[1,3]:=0.0;
 result[2,0]:=0.0;
 result[2,1]:=0.0;
 result[2,2]:=(-2.0)/fmn;
 result[2,3]:=0.0;
 result[3,0]:=(-(Right+Left))/rml;
 result[3,1]:=(-(Top+Bottom))/tmb;
 result[3,2]:=(-(zFar+zNear))/fmn;
 result[3,3]:=1.0;
end;

function Matrix4x4OrthoLH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
var rml,tmb,fmn:TKraftScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 result[0,0]:=2.0/rml;
 result[0,1]:=0.0;
 result[0,2]:=0.0;
 result[0,3]:=0.0;
 result[1,0]:=0.0;
 result[1,1]:=2.0/tmb;
 result[1,2]:=0.0;
 result[1,3]:=0.0;
 result[2,0]:=0.0;
 result[2,1]:=0.0;
 result[2,2]:=1.0/fmn;
 result[2,3]:=0.0;
 result[3,0]:=0;
 result[3,1]:=0;
 result[3,2]:=(-zNear)/fmn;
 result[3,3]:=1.0;
end;

function Matrix4x4OrthoRH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
var rml,tmb,fmn:TKraftScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 result[0,0]:=2.0/rml;
 result[0,1]:=0.0;
 result[0,2]:=0.0;
 result[0,3]:=0.0;
 result[1,0]:=0.0;
 result[1,1]:=2.0/tmb;
 result[1,2]:=0.0;
 result[1,3]:=0.0;
 result[2,0]:=0.0;
 result[2,1]:=0.0;
 result[2,2]:=1.0/fmn;
 result[2,3]:=0.0;
 result[3,0]:=0;
 result[3,1]:=0;
 result[3,2]:=zNear/fmn;
 result[3,3]:=1.0;
end;

function Matrix4x4OrthoOffCenterLH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
var rml,tmb,fmn:TKraftScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 result[0,0]:=2.0/rml;
 result[0,1]:=0.0;
 result[0,2]:=0.0;
 result[0,3]:=0.0;
 result[1,0]:=0.0;
 result[1,1]:=2.0/tmb;
 result[1,2]:=0.0;
 result[1,3]:=0.0;
 result[2,0]:=0.0;
 result[2,1]:=0.0;
 result[2,2]:=1.0/fmn;
 result[2,3]:=0.0;
 result[3,0]:=(Right+Left)/rml;
 result[3,1]:=(Top+Bottom)/tmb;
 result[3,2]:=zNear/fmn;
 result[3,3]:=1.0;
end;            

function Matrix4x4OrthoOffCenterRH(Left,Right,Bottom,Top,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
var rml,tmb,fmn:TKraftScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 result[0,0]:=2.0/rml;
 result[0,1]:=0.0;
 result[0,2]:=0.0;
 result[0,3]:=0.0;
 result[1,0]:=0.0;
 result[1,1]:=2.0/tmb;
 result[1,2]:=0.0;
 result[1,3]:=0.0;
 result[2,0]:=0.0;
 result[2,1]:=0.0;
 result[2,2]:=(-2.0)/fmn;
 result[2,3]:=0.0;
 result[3,0]:=(-(Right+Left))/rml;
 result[3,1]:=(-(Top+Bottom))/tmb;
 result[3,2]:=(-(zFar+zNear))/fmn;
 result[3,3]:=1.0;
end;

function Matrix4x4Perspective(fovy,Aspect,zNear,zFar:TKraftScalar):TKraftMatrix4x4;
(*)var Top,Right:TKraftScalar;
begin
 Top:=zNear*tan(fovy*pi/360.0);
 Right:=Top*Aspect;
 result:=Matrix4x4Frustum(-Right,Right,-Top,Top,zNear,zFar);
end;{(**)var Sine,Cotangent,ZDelta,Radians:TKraftScalar;
begin
 Radians:=(fovy*0.5)*DEG2RAD;
 ZDelta:=zFar-zNear;
 Sine:=sin(Radians);
 if not ((ZDelta=0) or (Sine=0) or (aspect=0)) then begin
  Cotangent:=cos(Radians)/Sine;
  result:=Matrix4x4Identity;
  result[0][0]:=Cotangent/aspect;
  result[1][1]:=Cotangent;
  result[2][2]:=(-(zFar+zNear))/ZDelta;
  result[2][3]:=-1-0;
  result[3][2]:=(-(2.0*zNear*zFar))/ZDelta;
  result[3][3]:=0.0;
 end;
end;{}

function Matrix4x4LookAt(const Eye,Center,Up:TKraftVector3):TKraftMatrix4x4;
var RightVector,UpVector,ForwardVector:TKraftVector3;
begin
 ForwardVector:=Vector3NormEx(Vector3Sub(Eye,Center));
 RightVector:=Vector3NormEx(Vector3Cross(Up,ForwardVector));
 UpVector:=Vector3NormEx(Vector3Cross(ForwardVector,RightVector));
 result[0,0]:=RightVector.x;
 result[1,0]:=RightVector.y;
 result[2,0]:=RightVector.z;
 result[3,0]:=-((RightVector.x*Eye.x)+(RightVector.y*Eye.y)+(RightVector.z*Eye.z));
 result[0,1]:=UpVector.x;
 result[1,1]:=UpVector.y;
 result[2,1]:=UpVector.z;
 result[3,1]:=-((UpVector.x*Eye.x)+(UpVector.y*Eye.y)+(UpVector.z*Eye.z));
 result[0,2]:=ForwardVector.x;
 result[1,2]:=ForwardVector.y;
 result[2,2]:=ForwardVector.z;
 result[3,2]:=-((ForwardVector.x*Eye.x)+(ForwardVector.y*Eye.y)+(ForwardVector.z*Eye.z));
 result[0,3]:=0.0;
 result[1,3]:=0.0;
 result[2,3]:=0.0;
 result[3,3]:=1.0;
end;

function Matrix4x4Fill(const Eye,RightVector,UpVector,ForwardVector:TKraftVector3):TKraftMatrix4x4;
begin
 result[0,0]:=RightVector.x;
 result[1,0]:=RightVector.y;
 result[2,0]:=RightVector.z;
 result[3,0]:=-((RightVector.x*Eye.x)+(RightVector.y*Eye.y)+(RightVector.z*Eye.z));
 result[0,1]:=UpVector.x;
 result[1,1]:=UpVector.y;
 result[2,1]:=UpVector.z;
 result[3,1]:=-((UpVector.x*Eye.x)+(UpVector.y*Eye.y)+(UpVector.z*Eye.z));
 result[0,2]:=ForwardVector.x;
 result[1,2]:=ForwardVector.y;
 result[2,2]:=ForwardVector.z;
 result[3,2]:=-((ForwardVector.x*Eye.x)+(ForwardVector.y*Eye.y)+(ForwardVector.z*Eye.z));
 result[0,3]:=0.0;
 result[1,3]:=0.0;
 result[2,3]:=0.0;
 result[3,3]:=1.0;
end;

function Matrix4x4ConstructX(const xAxis:TKraftVector3):TKraftMatrix4x4;
var a,b,c:TKraftVector3;
begin
 a:=Vector3NormEx(xAxis);
 result[0,0]:=a.x;
 result[0,1]:=a.y;
 result[0,2]:=a.z;
 result[0,3]:=0.0;
//b:=Vector3NormEx(Vector3Cross(Vector3(0,0,1),a));
 b:=Vector3NormEx(Vector3Perpendicular(a));
 result[1,0]:=b.x;
 result[1,1]:=b.y;
 result[1,2]:=b.z;
 result[1,3]:=0.0;
 c:=Vector3NormEx(Vector3Cross(b,a));
 result[2,0]:=c.x;
 result[2,1]:=c.y;
 result[2,2]:=c.z;
 result[2,3]:=0.0;
 result[3,0]:=0.0;
 result[3,1]:=0.0;
 result[3,2]:=0.0;
 result[3,3]:=1.0;
end;{}

function Matrix4x4ConstructY(const yAxis:TKraftVector3):TKraftMatrix4x4;
var a,b,c:TKraftVector3;
begin
 a:=Vector3NormEx(yAxis);
 result[1,0]:=a.x;
 result[1,1]:=a.y;
 result[1,2]:=a.z;
 result[1,3]:=0.0;
 b:=Vector3NormEx(Vector3Perpendicular(a));
 result[0,0]:=b.x;
 result[0,1]:=b.y;
 result[0,2]:=b.z;
 result[0,3]:=0.0;
 c:=Vector3Cross(b,a);
 result[2,0]:=c.x;
 result[2,1]:=c.y;
 result[2,2]:=c.z;
 result[2,3]:=0.0;
 result[3,0]:=0.0;
 result[3,1]:=0.0;
 result[3,2]:=0.0;
 result[3,3]:=1.0;
end;

function Matrix4x4ConstructZ(const zAxis:TKraftVector3):TKraftMatrix4x4;
var a,b,c:TKraftVector3;
begin
 a:=Vector3NormEx(zAxis);
 result[2,0]:=a.x;
 result[2,1]:=a.y;
 result[2,2]:=a.z;
 result[2,3]:=0.0;
 b:=Vector3NormEx(Vector3Perpendicular(a));
//b:=Vector3Sub(Vector3(0,1,0),Vector3ScalarMul(a,a.y));
 result[1,0]:=b.x;
 result[1,1]:=b.y;
 result[1,2]:=b.z;
 result[1,3]:=0.0;
 c:=Vector3Cross(b,a);
 result[0,0]:=c.x;
 result[0,1]:=c.y;
 result[0,2]:=c.z;
 result[0,3]:=0.0;
 result[3,0]:=0.0;
 result[3,1]:=0.0;
 result[3,2]:=0.0;
 result[3,3]:=1.0;
end;

function Matrix4x4ProjectionMatrixClip(const ProjectionMatrix:TKraftMatrix4x4;const ClipPlane:TKraftPlane):TKraftMatrix4x4;
var q,c:TKraftVector4;
begin
 result:=ProjectionMatrix;
 q.x:=(Sign(ClipPlane.Normal.x)+result[2,0])/result[0,0];
 q.y:=(Sign(ClipPlane.Normal.y)+result[2,1])/result[1,1];
 q.z:=-1.0;
 q.w:=(1.0+result[2,2])/result[3,2];
 c.x:=ClipPlane.Normal.x;
 c.y:=ClipPlane.Normal.y;
 c.z:=ClipPlane.Normal.z;
 c.w:=ClipPlane.Distance;
 c:=Vector4ScalarMul(c,2.0/Vector4Dot(c,q));
 result[0,2]:=c.x;
 result[1,2]:=c.y;
 result[2,2]:=c.z+1.0;
 result[3,2]:=c.w;
end;

function PlaneMatrixMul(const Plane:TKraftPlane;const Matrix:TKraftMatrix4x4):TKraftPlane;
begin
 result.Normal.x:=(Matrix[0,0]*Plane.Normal.x)+(Matrix[1,0]*Plane.Normal.y)+(Matrix[2,0]*Plane.Normal.z)+(Matrix[3,0]*Plane.Distance);
 result.Normal.y:=(Matrix[0,1]*Plane.Normal.x)+(Matrix[1,1]*Plane.Normal.y)+(Matrix[2,1]*Plane.Normal.z)+(Matrix[3,1]*Plane.Distance);
 result.Normal.z:=(Matrix[0,2]*Plane.Normal.x)+(Matrix[1,2]*Plane.Normal.y)+(Matrix[2,2]*Plane.Normal.z)+(Matrix[3,2]*Plane.Distance);
 result.Distance:=(Matrix[0,3]*Plane.Normal.x)+(Matrix[1,3]*Plane.Normal.y)+(Matrix[2,3]*Plane.Normal.z)+(Matrix[3,3]*Plane.Distance);
end;

function PlaneTransform(const Plane:TKraftPlane;const Matrix:TKraftMatrix4x4):TKraftPlane; overload;
begin
 result.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(Plane.Normal,Matrix4x4TermTranspose(Matrix4x4TermInverse(Matrix))));
 result.Distance:=-Vector3Dot(result.Normal,Vector3TermMatrixMul(Vector3ScalarMul(Plane.Normal,-Plane.Distance),Matrix));
end;

function PlaneTransform(const Plane:TKraftPlane;const Matrix,NormalMatrix:TKraftMatrix4x4):TKraftPlane; overload;
begin
 result.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(Plane.Normal,NormalMatrix));
 result.Distance:=-Vector3Dot(result.Normal,Vector3TermMatrixMul(Vector3ScalarMul(Plane.Normal,-Plane.Distance),Matrix));
end;

function PlaneFastTransform(const Plane:TKraftPlane;const Matrix:TKraftMatrix4x4):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
begin
 result.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(Plane.Normal,Matrix));
 result.Distance:=-Vector3Dot(result.Normal,Vector3TermMatrixMul(Vector3ScalarMul(Plane.Normal,-Plane.Distance),Matrix));
end;

procedure PlaneNormalize(var Plane:TKraftPlane); {$ifdef caninline}inline;{$endif}
var l:TKraftScalar;
begin
 l:=sqr(Plane.Normal.x)+sqr(Plane.Normal.y)+sqr(Plane.Normal.z);
 if l>0.0 then begin
  l:=sqrt(l);
  Plane.Normal.x:=Plane.Normal.x/l;
  Plane.Normal.y:=Plane.Normal.y/l;
  Plane.Normal.z:=Plane.Normal.z/l;
  Plane.Distance:=Plane.Distance/l;
 end else begin
  Plane.Normal.x:=0.0;
  Plane.Normal.y:=0.0;
  Plane.Normal.z:=0.0;
  Plane.Distance:=0.0;
 end;
end;

function PlaneVectorDistance(const Plane:TKraftPlane;const Point:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=(Plane.Normal.x*Point.x)+(Plane.Normal.y*Point.y)+(Plane.Normal.z*Point.z)+Plane.Distance;
end;

function PlaneVectorDistance(const Plane:TKraftPlane;const Point:TKraftVector4):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=(Plane.Normal.x*Point.x)+(Plane.Normal.y*Point.y)+(Plane.Normal.z*Point.z)+(Plane.Distance*Point.w);
end;

function PlaneFromPoints(const p1,p2,p3:TKraftVector3):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
var n:TKraftVector3;
begin
 n:=Vector3NormEx(Vector3Cross(Vector3Sub(p2,p1),Vector3Sub(p3,p1)));
 result.Normal.x:=n.x;
 result.Normal.y:=n.y;
 result.Normal.z:=n.z;
 result.Distance:=-((result.Normal.x*p1.x)+(result.Normal.y*p1.y)+(result.Normal.z*p1.z));
end;

function PlaneFromPoints(const p1,p2,p3:TKraftVector4):TKraftPlane; overload; {$ifdef caninline}inline;{$endif}
var n:TKraftVector4;
begin
 n:=Vector4Norm(Vector4Cross(Vector4Sub(p2,p1),Vector4Sub(p3,p1)));
 result.Normal.x:=n.x;
 result.Normal.y:=n.y;
 result.Normal.z:=n.z;
 result.Distance:=-((result.Normal.x*p1.x)+(result.Normal.y*p1.y)+(result.Normal.z*p1.z));
end;

function QuaternionNormal(const AQuaternion:TKraftQuaternion):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [AQuaternion]
 mulps xmm0,xmm0
 movhlps xmm1,xmm0
 addps xmm0,xmm1
 pshufd xmm1,xmm0,$01
 addss xmm0,xmm1
 sqrtss xmm0,xmm0
 movss dword ptr [result],xmm0
end;
{$else}
begin
 result:=sqrt(sqr(AQuaternion.x)+sqr(AQuaternion.y)+sqr(AQuaternion.z)+sqr(AQuaternion.w));
end;
{$endif}
                            
function QuaternionLengthSquared(const AQuaternion:TKraftQuaternion):TKraftScalar; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [AQuaternion]
 mulps xmm0,xmm0
 movhlps xmm1,xmm0
 addps xmm0,xmm1
 pshufd xmm1,xmm0,$01
 addss xmm0,xmm1
 movss dword ptr [result],xmm0
end;
{$else}
begin
 result:=sqr(AQuaternion.x)+sqr(AQuaternion.y)+sqr(AQuaternion.z)+sqr(AQuaternion.w);
end;
{$endif}

procedure QuaternionNormalize(var AQuaternion:TKraftQuaternion); {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
{movups xmm2,dqword ptr [AQuaternion]
 movaps xmm0,xmm2
 mulps xmm0,xmm0
 movhlps xmm1,xmm0
 addps xmm0,xmm1
 pshufd xmm1,xmm0,$01
 addss xmm0,xmm1
 movss xmm3,xmm0
 xorps xmm1,xmm1
 cmpps xmm3,xmm1,4
 rsqrtss xmm0,xmm0
 andps xmm0,xmm3
 shufps xmm0,xmm0,$00
 mulps xmm2,xmm0
 movups dqword ptr [AQuaternion],xmm2}
 movups xmm2,dqword ptr [AQuaternion]
 movaps xmm0,xmm2
 mulps xmm0,xmm0
 movhlps xmm1,xmm0
 addps xmm0,xmm1
 pshufd xmm1,xmm0,$01
 addss xmm0,xmm1
 sqrtss xmm0,xmm0
 shufps xmm0,xmm0,$00
 divps xmm2,xmm0
 subps xmm1,xmm2
 cmpps xmm1,xmm0,7
 andps xmm2,xmm1
 movups dqword ptr [AQuaternion],xmm2
end;
{$else}
var Normal:TKraftScalar;
begin
 Normal:=sqrt(sqr(AQuaternion.x)+sqr(AQuaternion.y)+sqr(AQuaternion.z)+sqr(AQuaternion.w));
 if Normal>0.0 then begin
  Normal:=1.0/Normal;
 end;
 AQuaternion.x:=AQuaternion.x*Normal;
 AQuaternion.y:=AQuaternion.y*Normal;
 AQuaternion.z:=AQuaternion.z*Normal;
 AQuaternion.w:=AQuaternion.w*Normal;
end;
{$endif}

function QuaternionTermNormalize(const AQuaternion:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm2,dqword ptr [AQuaternion]
 movaps xmm0,xmm2
 mulps xmm0,xmm0
 movhlps xmm1,xmm0
 addps xmm0,xmm1
 pshufd xmm1,xmm0,$01
 addss xmm0,xmm1
 sqrtss xmm0,xmm0
 shufps xmm0,xmm0,$00
 divps xmm2,xmm0
 subps xmm1,xmm2
 cmpps xmm1,xmm0,7
 andps xmm2,xmm1
 movups dqword ptr [result],xmm2
end;
{$else}
var Normal:TKraftScalar;
begin
 Normal:=sqrt(sqr(AQuaternion.x)+sqr(AQuaternion.y)+sqr(AQuaternion.z)+sqr(AQuaternion.w));
 if Normal>0.0 then begin
  Normal:=1.0/Normal;
 end;
 result.x:=AQuaternion.x*Normal;
 result.y:=AQuaternion.y*Normal;
 result.z:=AQuaternion.z*Normal;
 result.w:=AQuaternion.w*Normal;
end;
{$endif}

function QuaternionNeg(const AQuaternion:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm1,dqword ptr [AQuaternion]
 xorps xmm0,xmm0
 subps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=-AQuaternion.x;
 result.y:=-AQuaternion.y;
 result.z:=-AQuaternion.z;
 result.w:=-AQuaternion.w;
end;
{$endif}

function QuaternionConjugate(const AQuaternion:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
const XORMask:array[0..3] of longword=($80000000,$80000000,$80000000,$00000000);
asm
 movups xmm0,dqword ptr [AQuaternion]
 movups xmm1,dqword ptr [XORMask]
 xorps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=-AQuaternion.x;
 result.y:=-AQuaternion.y;
 result.z:=-AQuaternion.z;
 result.w:=AQuaternion.w;
end;
{$endif}

function QuaternionInverse(const AQuaternion:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
const XORMask:array[0..3] of longword=($80000000,$80000000,$80000000,$00000000);
asm
 movups xmm2,dqword ptr [AQuaternion]
 movups xmm3,dqword ptr [XORMask]
 movaps xmm0,xmm2
 mulps xmm0,xmm0
 movhlps xmm1,xmm0
 addps xmm0,xmm1
 pshufd xmm1,xmm0,$01
 addss xmm0,xmm1
 sqrtss xmm0,xmm0
 shufps xmm0,xmm0,$00
 divps xmm2,xmm0
 xorps xmm2,xmm3
 movups dqword ptr [result],xmm2
end;
{$else}
var Normal:TKraftScalar;
begin
 Normal:=sqrt(sqr(AQuaternion.x)+sqr(AQuaternion.y)+sqr(AQuaternion.z)+sqr(AQuaternion.w));
 if Normal>0.0 then begin
  Normal:=1.0/Normal;
 end;
 result.x:=-(AQuaternion.x*Normal);
 result.y:=-(AQuaternion.y*Normal);
 result.z:=-(AQuaternion.z*Normal);
 result.w:=(AQuaternion.w*Normal);
end;
{$endif}

function QuaternionAdd(const q1,q2:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [q1]
 movups xmm1,dqword ptr [q2]
 addps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=q1.x+q2.x;
 result.y:=q1.y+q2.y;
 result.z:=q1.z+q2.z;
 result.w:=q1.w+q2.w;
end;
{$endif}

function QuaternionSub(const q1,q2:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm
 movups xmm0,dqword ptr [q1]
 movups xmm1,dqword ptr [q2]
 subps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=q1.x-q2.x;
 result.y:=q1.y-q2.y;
 result.z:=q1.z-q2.z;
 result.w:=q1.w-q2.w;
end;
{$endif}

function QuaternionScalarMul(const q:TKraftQuaternion;const s:TKraftScalar):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
asm                    
 movups xmm0,dqword ptr [q]
 movss xmm1,dword ptr [s]
 shufps xmm1,xmm1,$00
 mulps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=q.x*s;
 result.y:=q.y*s;
 result.z:=q.z*s;
 result.w:=q.w*s;
end;
{$endif}

function QuaternionMul(const q1,q2:TKraftQuaternion):TKraftQuaternion; {$ifdef CPU386ASMForSinglePrecision}assembler;
const XORMaskW:array[0..3] of longword=($00000000,$00000000,$00000000,$80000000);
asm
 movups xmm0,dqword ptr [q1]
 movups xmm1,dqword ptr [q2]
 movups xmm5,dqword ptr [XORMaskW]
 movaps xmm2,xmm0
 movaps xmm3,xmm1
 movaps xmm4,xmm1
 shufps xmm0,xmm0,$ff // 011111111b
 shufps xmm1,xmm1,$3f // 000111111b
 shufps xmm2,xmm2,$24 // 000100100b
 mulps xmm0,xmm3
 mulps xmm1,xmm2
 shufps xmm3,xmm3,$52 // 001010010b
 shufps xmm2,xmm2,$49 // 001001001b
 shufps xmm4,xmm4,$89 // 010001001b
 mulps xmm3,xmm2
 shufps xmm2,xmm2,$49 // 001001001b
 addps xmm1,xmm3
 mulps xmm2,xmm4
 xorps xmm1,xmm5
 subps xmm0,xmm2
 addps xmm0,xmm1
 movups dqword ptr [result],xmm0
end;
{$else}
begin
 result.x:=((q1.w*q2.x)+(q1.x*q2.w)+(q1.y*q2.z))-(q1.z*q2.y);
 result.y:=((q1.w*q2.y)+(q1.y*q2.w)+(q1.z*q2.x))-(q1.x*q2.z);
 result.z:=((q1.w*q2.z)+(q1.z*q2.w)+(q1.x*q2.y))-(q1.y*q2.x);
 result.w:=(q1.w*q2.w)-((q1.x*q2.x)+(q1.y*q2.y)+(q1.z*q2.z));
end;
{$endif}

function QuaternionRotateAroundAxis(const q1,q2:TKraftQuaternion):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
begin
 result.x:=((q1.x*q2.w)+(q1.z*q2.y))-(q1.y*q2.z);
 result.y:=((q1.x*q2.z)+(q1.y*q2.w))-(q1.z*q2.x);
 result.z:=((q1.y*q2.x)+(q1.z*q2.w))-(q1.x*q2.y);
 result.w:=((q1.x*q2.x)+(q1.y*q2.y))+(q1.z*q2.z);
end;

function QuaternionFromAxisAngle(const Axis:TKraftVector3;Angle:TKraftScalar):TKraftQuaternion; overload; {$ifdef caninline}inline;{$endif}
var sa2:TKraftScalar;
begin
 result.w:=cos(Angle*0.5);
 sa2:=sin(Angle*0.5);
 result.x:=Axis.x*sa2;
 result.y:=Axis.y*sa2;
 result.z:=Axis.z*sa2;
 QuaternionNormalize(result);
end;

function QuaternionFromSpherical(const Latitude,Longitude:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
begin
 result.x:=cos(Latitude)*sin(Longitude);
 result.y:=sin(Latitude);
 result.z:=cos(Latitude)*cos(Longitude);
 result.w:=0.0;
end;

procedure QuaternionToSpherical(const q:TKraftQuaternion;var Latitude,Longitude:TKraftScalar);
var y:TKraftScalar;
begin
 y:=q.y;
 if y<-1.0 then begin
  y:=-1.0;
 end else if y>1.0 then begin
  y:=1.0;
 end;
 Latitude:=ArcSin(y);
 if (sqr(q.x)+sqr(q.z))>0.00005 then begin
  Longitude:=ArcTan2(q.x,q.z);
 end else begin
  Longitude:=0.0;
 end;
end;

function QuaternionFromAngles(const Pitch,Yaw,Roll:TKraftScalar):TKraftQuaternion; overload; {$ifdef caninline}inline;{$endif}
var sp,sy,sr,cp,cy,cr:TKraftScalar;
begin
 sp:=sin(Pitch*0.5);
 sy:=sin(Yaw*0.5);
 sr:=sin(Roll*0.5);
 cp:=cos(Pitch*0.5);
 cy:=cos(Yaw*0.5);
 cr:=cos(Roll*0.5);
 result.x:=(sr*cp*cy)-(cr*sp*sy);
 result.y:=(cr*sp*cy)+(sr*cp*sy);
 result.z:=(cr*cp*sy)-(sr*sp*cy);
 result.w:=(cr*cp*cy)+(sr*sp*sy);
 QuaternionNormalize(result);
end;

function QuaternionFromAngles(const Angles:TKraftAngles):TKraftQuaternion; overload; {$ifdef caninline}inline;{$endif}
var sp,sy,sr,cp,cy,cr:TKraftScalar;
begin
 sp:=sin(Angles.Pitch*0.5);
 sy:=sin(Angles.Yaw*0.5);
 sr:=sin(Angles.Roll*0.5);
 cp:=cos(Angles.Pitch*0.5);
 cy:=cos(Angles.Yaw*0.5);
 cr:=cos(Angles.Roll*0.5);
 result.x:=(sr*cp*cy)-(cr*sp*sy);
 result.y:=(cr*sp*cy)+(sr*cp*sy);
 result.z:=(cr*cp*sy)-(sr*sp*cy);
 result.w:=(cr*cp*cy)+(sr*sp*sy);
 QuaternionNormalize(result);
end;

function QuaternionFromMatrix3x3(const AMatrix:TKraftMatrix3x3):TKraftQuaternion;
var t,s:TKraftScalar;
begin
 t:=AMatrix[0,0]+(AMatrix[1,1]+AMatrix[2,2]);
 if t>2.9999999 then begin
  result.x:=0.0;
  result.y:=0.0;
  result.z:=0.0;
  result.w:=1.0;
 end else if t>0.0000001 then begin
  s:=sqrt(1.0+t)*2.0;
  result.x:=(AMatrix[1,2]-AMatrix[2,1])/s;
  result.y:=(AMatrix[2,0]-AMatrix[0,2])/s;
  result.z:=(AMatrix[0,1]-AMatrix[1,0])/s;
  result.w:=s*0.25;
 end else if (AMatrix[0,0]>AMatrix[1,1]) and (AMatrix[0,0]>AMatrix[2,2]) then begin
  s:=sqrt(1.0+(AMatrix[0,0]-(AMatrix[1,1]+AMatrix[2,2])))*2.0;
  result.x:=s*0.25;
  result.y:=(AMatrix[1,0]+AMatrix[0,1])/s;
  result.z:=(AMatrix[2,0]+AMatrix[0,2])/s;
  result.w:=(AMatrix[1,2]-AMatrix[2,1])/s;
 end else if AMatrix[1,1]>AMatrix[2,2] then begin
  s:=sqrt(1.0+(AMatrix[1,1]-(AMatrix[0,0]+AMatrix[2,2])))*2.0;
  result.x:=(AMatrix[1,0]+AMatrix[0,1])/s;
  result.y:=s*0.25;
  result.z:=(AMatrix[2,1]+AMatrix[1,2])/s;
  result.w:=(AMatrix[2,0]-AMatrix[0,2])/s;
 end else begin
  s:=sqrt(1.0+(AMatrix[2,2]-(AMatrix[0,0]+AMatrix[1,1])))*2.0;
  result.x:=(AMatrix[2,0]+AMatrix[0,2])/s;
  result.y:=(AMatrix[2,1]+AMatrix[1,2])/s;
  result.z:=s*0.25;
  result.w:=(AMatrix[0,1]-AMatrix[1,0])/s;
 end;
 QuaternionNormalize(result);
end;
{var xx,yx,zx,xy,yy,zy,xz,yz,zz,Trace,Radicand,Scale,TempX,TempY,TempZ,TempW:TKraftScalar;
    NegativeTrace,ZgtX,ZgtY,YgtX,LargestXorY,LargestYorZ,LargestZorX:boolean;
begin
 xx:=AMatrix[0,0];
 yx:=AMatrix[0,1];
 zx:=AMatrix[0,2];
 xy:=AMatrix[1,0];
 yy:=AMatrix[1,1];
 zy:=AMatrix[1,2];
 xz:=AMatrix[2,0];
 yz:=AMatrix[2,1];
 zz:=AMatrix[2,2];
 Trace:=(xx+yy)+zz;
 NegativeTrace:=Trace<0.0;
 ZgtX:=zz>xx;
 ZgtY:=zz>yy;
 YgtX:=yy>xx;
 LargestXorY:=NegativeTrace and ((not ZgtX) or not ZgtY);
 LargestYorZ:=NegativeTrace and (YgtX or ZgtX);
 LargestZorX:=NegativeTrace and (ZgtY or not YgtX);
 if LargestXorY then begin
  zz:=-zz;
  xy:=-xy;
 end;
 if LargestYorZ then begin
  xx:=-xx;
  yz:=-yz;
 end;
 if LargestZorX then begin
  yy:=-yy;
  zx:=-zx;
 end;
 Radicand:=((xx+yy)+zz)+1.0;
 Scale:=0.5/sqrt(Radicand);
 TempX:=(zy-yz)*Scale;
 TempY:=(xz-zx)*Scale;
 TempZ:=(yx-xy)*Scale;
 TempW:=Radicand*Scale;
 if LargestXorY then begin
  result.x:=TempW;
  result.y:=TempZ;
  result.z:=TempY;
  result.w:=TempX;
 end else begin
  result.x:=TempX;
  result.y:=TempY;
  result.z:=TempZ;
  result.w:=TempW;
 end;
 if LargestYorZ then begin
  TempX:=result.x;
  TempZ:=result.z;
  result.x:=result.y;
  result.y:=TempX;
  result.z:=result.w;
  result.w:=TempZ;
 end;
end;{}

function QuaternionToMatrix3x3(AQuaternion:TKraftQuaternion):TKraftMatrix3x3;
var qx2,qy2,qz2,qxqx2,qxqy2,qxqz2,qxqw2,qyqy2,qyqz2,qyqw2,qzqz2,qzqw2:TKraftScalar;
begin
 QuaternionNormalize(AQuaternion);
 qx2:=AQuaternion.x+AQuaternion.x;
 qy2:=AQuaternion.y+AQuaternion.y;
 qz2:=AQuaternion.z+AQuaternion.z;
 qxqx2:=AQuaternion.x*qx2;
 qxqy2:=AQuaternion.x*qy2;
 qxqz2:=AQuaternion.x*qz2;
 qxqw2:=AQuaternion.w*qx2;
 qyqy2:=AQuaternion.y*qy2;
 qyqz2:=AQuaternion.y*qz2;
 qyqw2:=AQuaternion.w*qy2;
 qzqz2:=AQuaternion.z*qz2;
 qzqw2:=AQuaternion.w*qz2;
 result[0,0]:=1.0-(qyqy2+qzqz2);
 result[0,1]:=qxqy2+qzqw2;
 result[0,2]:=qxqz2-qyqw2;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=qxqy2-qzqw2;
 result[1,1]:=1.0-(qxqx2+qzqz2);
 result[1,2]:=qyqz2+qxqw2;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=qxqz2+qyqw2;
 result[2,1]:=qyqz2-qxqw2;
 result[2,2]:=1.0-(qxqx2+qyqy2);
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function QuaternionFromTangentSpaceMatrix3x3(AMatrix:TKraftMatrix3x3):TKraftQuaternion;
const Threshold=1.0/127.0;
var Scale,t,s,Renormalization:TKraftScalar;
begin
 if ((((((AMatrix[0,0]*AMatrix[1,1]*AMatrix[2,2])+
         (AMatrix[0,1]*AMatrix[1,2]*AMatrix[2,0])
        )+
        (AMatrix[0,2]*AMatrix[1,0]*AMatrix[2,1])
       )-
       (AMatrix[0,2]*AMatrix[1,1]*AMatrix[2,0])
      )-
      (AMatrix[0,1]*AMatrix[1,0]*AMatrix[2,2])
     )-
     (AMatrix[0,0]*AMatrix[1,2]*AMatrix[2,1])
    )<0.0 then begin
  // Reflection matrix, so flip y axis in case the tangent frame encodes a reflection
  Scale:=-1.0;
  AMatrix[2,0]:=-AMatrix[2,0];
  AMatrix[2,1]:=-AMatrix[2,1];
  AMatrix[2,2]:=-AMatrix[2,2];
 end else begin
  // Rotation matrix, so nothing is doing to do
  Scale:=1.0;
 end;
 begin
  // Convert to quaternion
  t:=AMatrix[0,0]+(AMatrix[1,1]+AMatrix[2,2]);
  if t>2.9999999 then begin
   result.x:=0.0;
   result.y:=0.0;
   result.z:=0.0;
   result.w:=1.0;
  end else if t>0.0000001 then begin
   s:=sqrt(1.0+t)*2.0;
   result.x:=(AMatrix[1,2]-AMatrix[2,1])/s;
   result.y:=(AMatrix[2,0]-AMatrix[0,2])/s;
   result.z:=(AMatrix[0,1]-AMatrix[1,0])/s;
   result.w:=s*0.25;
  end else if (AMatrix[0,0]>AMatrix[1,1]) and (AMatrix[0,0]>AMatrix[2,2]) then begin
   s:=sqrt(1.0+(AMatrix[0,0]-(AMatrix[1,1]+AMatrix[2,2])))*2.0;
   result.x:=s*0.25;
   result.y:=(AMatrix[1,0]+AMatrix[0,1])/s;
   result.z:=(AMatrix[2,0]+AMatrix[0,2])/s;
   result.w:=(AMatrix[1,2]-AMatrix[2,1])/s;
  end else if AMatrix[1,1]>AMatrix[2,2] then begin
   s:=sqrt(1.0+(AMatrix[1,1]-(AMatrix[0,0]+AMatrix[2,2])))*2.0;
   result.x:=(AMatrix[1,0]+AMatrix[0,1])/s;
   result.y:=s*0.25;
   result.z:=(AMatrix[2,1]+AMatrix[1,2])/s;
   result.w:=(AMatrix[2,0]-AMatrix[0,2])/s;
  end else begin
   s:=sqrt(1.0+(AMatrix[2,2]-(AMatrix[0,0]+AMatrix[1,1])))*2.0;
   result.x:=(AMatrix[2,0]+AMatrix[0,2])/s;
   result.y:=(AMatrix[2,1]+AMatrix[1,2])/s;
   result.z:=s*0.25;
   result.w:=(AMatrix[0,1]-AMatrix[1,0])/s;
  end;
  QuaternionNormalize(result);
 end;
 begin
  // Make sure, that we don't end up with 0 as w component
  if abs(result.w)<=Threshold then begin
   Renormalization:=sqrt(1.0-sqr(Threshold));
   result.x:=result.x*Renormalization;
   result.y:=result.y*Renormalization;
   result.z:=result.z*Renormalization;
   if result.w<0.0 then begin
    result.w:=-Threshold;
   end else begin
    result.w:=Threshold;
   end;
  end;
 end;
 if ((Scale<0.0) and (result.w>=0.0)) or ((Scale>=0.0) and (result.w<0.0)) then begin
  // Encode reflection into quaternion's w element by making sign of w negative,
  // if y axis needs to be flipped, otherwise it stays positive
  result.x:=-result.x;
  result.y:=-result.y;
  result.z:=-result.z;
  result.w:=-result.w;
 end;
end;

function QuaternionToTangentSpaceMatrix3x3(AQuaternion:TKraftQuaternion):TKraftMatrix3x3;
var qx2,qy2,qz2,qxqx2,qxqy2,qxqz2,qxqw2,qyqy2,qyqz2,qyqw2,qzqz2,qzqw2:TKraftScalar;
begin
 QuaternionNormalize(AQuaternion);
 qx2:=AQuaternion.x+AQuaternion.x;
 qy2:=AQuaternion.y+AQuaternion.y;
 qz2:=AQuaternion.z+AQuaternion.z;
 qxqx2:=AQuaternion.x*qx2;
 qxqy2:=AQuaternion.x*qy2;
 qxqz2:=AQuaternion.x*qz2;
 qxqw2:=AQuaternion.w*qx2;
 qyqy2:=AQuaternion.y*qy2;
 qyqz2:=AQuaternion.y*qz2;
 qyqw2:=AQuaternion.w*qy2;
 qzqz2:=AQuaternion.z*qz2;
 qzqw2:=AQuaternion.w*qz2;
 result[0,0]:=1.0-(qyqy2+qzqz2);
 result[0,1]:=qxqy2+qzqw2;
 result[0,2]:=qxqz2-qyqw2;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=qxqy2-qzqw2;
 result[1,1]:=1.0-(qxqx2+qzqz2);
 result[1,2]:=qyqz2+qxqw2;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=qxqz2+qyqw2;
 result[2,1]:=qyqz2-qxqw2;
 result[2,2]:=1.0-(qxqx2+qyqy2);
 if AQuaternion.w<0.0 then begin
  result[2,0]:=-result[2,0];
  result[2,1]:=-result[2,1];
  result[2,2]:=-result[2,2];
 end;
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function QuaternionFromMatrix4x4(const AMatrix:TKraftMatrix4x4):TKraftQuaternion;
var t,s:TKraftScalar;
begin
 t:=AMatrix[0,0]+(AMatrix[1,1]+AMatrix[2,2]);
 if t>2.9999999 then begin
  result.x:=0.0;
  result.y:=0.0;
  result.z:=0.0;
  result.w:=1.0;
 end else if t>0.0000001 then begin
  s:=sqrt(1.0+t)*2.0;
  result.x:=(AMatrix[1,2]-AMatrix[2,1])/s;
  result.y:=(AMatrix[2,0]-AMatrix[0,2])/s;
  result.z:=(AMatrix[0,1]-AMatrix[1,0])/s;
  result.w:=s*0.25;
 end else if (AMatrix[0,0]>AMatrix[1,1]) and (AMatrix[0,0]>AMatrix[2,2]) then begin
  s:=sqrt(1.0+(AMatrix[0,0]-(AMatrix[1,1]+AMatrix[2,2])))*2.0;
  result.x:=s*0.25;
  result.y:=(AMatrix[1,0]+AMatrix[0,1])/s;
  result.z:=(AMatrix[2,0]+AMatrix[0,2])/s;
  result.w:=(AMatrix[1,2]-AMatrix[2,1])/s;
 end else if AMatrix[1,1]>AMatrix[2,2] then begin
  s:=sqrt(1.0+(AMatrix[1,1]-(AMatrix[0,0]+AMatrix[2,2])))*2.0;
  result.x:=(AMatrix[1,0]+AMatrix[0,1])/s;
  result.y:=s*0.25;
  result.z:=(AMatrix[2,1]+AMatrix[1,2])/s;
  result.w:=(AMatrix[2,0]-AMatrix[0,2])/s;
 end else begin
  s:=sqrt(1.0+(AMatrix[2,2]-(AMatrix[0,0]+AMatrix[1,1])))*2.0;
  result.x:=(AMatrix[2,0]+AMatrix[0,2])/s;
  result.y:=(AMatrix[2,1]+AMatrix[1,2])/s;
  result.z:=s*0.25;
  result.w:=(AMatrix[0,1]-AMatrix[1,0])/s;
 end;
 QuaternionNormalize(result);
end;
{var xx,yx,zx,xy,yy,zy,xz,yz,zz,Trace,Radicand,Scale,TempX,TempY,TempZ,TempW:TKraftScalar;
    NegativeTrace,ZgtX,ZgtY,YgtX,LargestXorY,LargestYorZ,LargestZorX:boolean;
begin
 xx:=AMatrix[0,0];
 yx:=AMatrix[0,1];
 zx:=AMatrix[0,2];
 xy:=AMatrix[1,0];
 yy:=AMatrix[1,1];
 zy:=AMatrix[1,2];
 xz:=AMatrix[2,0];
 yz:=AMatrix[2,1];
 zz:=AMatrix[2,2];
 Trace:=(xx+yy)+zz;
 NegativeTrace:=Trace<0.0;
 ZgtX:=zz>xx;
 ZgtY:=zz>yy;
 YgtX:=yy>xx;
 LargestXorY:=NegativeTrace and ((not ZgtX) or not ZgtY);
 LargestYorZ:=NegativeTrace and (YgtX or ZgtX);
 LargestZorX:=NegativeTrace and (ZgtY or not YgtX);
 if LargestXorY then begin
  zz:=-zz;
  xy:=-xy;
 end;
 if LargestYorZ then begin
  xx:=-xx;
  yz:=-yz;
 end;
 if LargestZorX then begin
  yy:=-yy;
  zx:=-zx;
 end;
 Radicand:=((xx+yy)+zz)+1.0;
 Scale:=0.5/sqrt(Radicand);
 TempX:=(zy-yz)*Scale;
 TempY:=(xz-zx)*Scale;
 TempZ:=(yx-xy)*Scale;
 TempW:=Radicand*Scale;
 if LargestXorY then begin
  result.x:=TempW;
  result.y:=TempZ;
  result.z:=TempY;
  result.w:=TempX;
 end else begin
  result.x:=TempX;
  result.y:=TempY;
  result.z:=TempZ;
  result.w:=TempW;
 end;
 if LargestYorZ then begin
  TempX:=result.x;
  TempZ:=result.z;
  result.x:=result.y;
  result.y:=TempX;
  result.z:=result.w;
  result.w:=TempZ;
 end;
end;{}

function QuaternionToMatrix4x4(AQuaternion:TKraftQuaternion):TKraftMatrix4x4;
var qx2,qy2,qz2,qxqx2,qxqy2,qxqz2,qxqw2,qyqy2,qyqz2,qyqw2,qzqz2,qzqw2:TKraftScalar;
begin
 QuaternionNormalize(AQuaternion);
 qx2:=AQuaternion.x+AQuaternion.x;
 qy2:=AQuaternion.y+AQuaternion.y;
 qz2:=AQuaternion.z+AQuaternion.z;
 qxqx2:=AQuaternion.x*qx2;
 qxqy2:=AQuaternion.x*qy2;
 qxqz2:=AQuaternion.x*qz2;
 qxqw2:=AQuaternion.w*qx2;
 qyqy2:=AQuaternion.y*qy2;
 qyqz2:=AQuaternion.y*qz2;
 qyqw2:=AQuaternion.w*qy2;
 qzqz2:=AQuaternion.z*qz2;
 qzqw2:=AQuaternion.w*qz2;
 result[0,0]:=1.0-(qyqy2+qzqz2);
 result[0,1]:=qxqy2+qzqw2;
 result[0,2]:=qxqz2-qyqw2;
 result[0,3]:=0.0;
 result[1,0]:=qxqy2-qzqw2;
 result[1,1]:=1.0-(qxqx2+qzqz2);
 result[1,2]:=qyqz2+qxqw2;
 result[1,3]:=0.0;
 result[2,0]:=qxqz2+qyqw2;
 result[2,1]:=qyqz2-qxqw2;
 result[2,2]:=1.0-(qxqx2+qyqy2);
 result[2,3]:=0.0;
 result[3,0]:=0.0;
 result[3,1]:=0.0;
 result[3,2]:=0.0;
 result[3,3]:=1.0;
end;

function QuaternionToEuler(const AQuaternion:TKraftQuaternion):TKraftVector3; {$ifdef caninline}inline;{$endif}
begin
 result.x:=ArcTan2(2.0*((AQuaternion.x*AQuaternion.y)+(AQuaternion.z*AQuaternion.w)),1.0-(2.0*(sqr(AQuaternion.y)+sqr(AQuaternion.z))));
 result.y:=ArcSin(2.0*((AQuaternion.x*AQuaternion.z)-(AQuaternion.y*AQuaternion.w)));
 result.z:=ArcTan2(2.0*((AQuaternion.x*AQuaternion.w)+(AQuaternion.y*AQuaternion.z)),1.0-(2.0*(sqr(AQuaternion.z)+sqr(AQuaternion.w))));
end;

procedure QuaternionToAxisAngle(AQuaternion:TKraftQuaternion;var Axis:TKraftVector3;var Angle:TKraftScalar); {$ifdef caninline}inline;{$endif}
var SinAngle:TKraftScalar;
begin
 QuaternionNormalize(AQuaternion);
 SinAngle:=sqrt(1.0-sqr(AQuaternion.w));
 if abs(SinAngle)<EPSILON then begin
  SinAngle:=1.0;
 end;
 Angle:=2.0*ArcCos(AQuaternion.w);
 Axis.x:=AQuaternion.x/SinAngle;
 Axis.y:=AQuaternion.y/SinAngle;
 Axis.z:=AQuaternion.z/SinAngle;
end;

function QuaternionGenerator(AQuaternion:TKraftQuaternion):TKraftVector3; {$ifdef caninline}inline;{$endif}
var s:TKraftScalar;
begin
 s:=sqrt(1.0-sqr(AQuaternion.w));
 result.x:=AQuaternion.x;
 result.y:=AQuaternion.y;
 result.z:=AQuaternion.z;
 if s>0.0 then begin
  result:=Vector3ScalarMul(result,s);
 end;
 result:=Vector3ScalarMul(result,2.0*ArcTan2(s,AQuaternion.w));
end;

function QuaternionLerp(const q1,q2:TKraftQuaternion;const t:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
var it,sf:TKraftScalar;
begin
 if ((q1.x*q2.x)+(q1.y*q2.y)+(q1.z*q2.z)+(q1.w*q2.w))<0.0 then begin
  sf:=-1.0;
 end else begin
  sf:=1.0;
 end;
 it:=1.0-t;
 result.x:=(it*q1.x)+(t*(sf*q2.x));
 result.y:=(it*q1.y)+(t*(sf*q2.y));
 result.z:=(it*q1.z)+(t*(sf*q2.z));
 result.w:=(it*q1.w)+(t*(sf*q2.w));
end;

function QuaternionNlerp(const q1,q2:TKraftQuaternion;const t:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
var it,sf:TKraftScalar;
begin
 if ((q1.x*q2.x)+(q1.y*q2.y)+(q1.z*q2.z)+(q1.w*q2.w))<0.0 then begin
  sf:=-1.0;
 end else begin
  sf:=1.0;
 end;
 it:=1.0-t;
 result.x:=(it*q1.x)+(t*(sf*q2.x));
 result.y:=(it*q1.y)+(t*(sf*q2.y));
 result.z:=(it*q1.z)+(t*(sf*q2.z));
 result.w:=(it*q1.w)+(t*(sf*q2.w));
 QuaternionNormalize(result);
end;

function QuaternionSlerp(const q1,q2:TKraftQuaternion;const t:TKraftScalar):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
var Omega,co,so,s0,s1,s2:TKraftScalar;
begin
 co:=(q1.x*q2.x)+(q1.y*q2.y)+(q1.z*q2.z)+(q1.w*q2.w);
 if co<0.0 then begin
  co:=-co;
  s2:=-1.0;
 end else begin
  s2:=1.0;
 end;
 if (1.0-co)>EPSILON then begin
  Omega:=ArcCos(co);
  so:=sin(Omega);
  s0:=sin((1.0-t)*Omega)/so;
  s1:=sin(t*Omega)/so;
 end else begin
  s0:=1.0-t;
  s1:=t;
 end;
 result.x:=(s0*q1.x)+(s1*(s2*q2.x));
 result.y:=(s0*q1.y)+(s1*(s2*q2.y));
 result.z:=(s0*q1.z)+(s1*(s2*q2.z));
 result.w:=(s0*q1.w)+(s1*(s2*q2.w));
end;

function QuaternionIntegrate(const q:TKraftQuaternion;const Omega:TKraftVector3;const DeltaTime:TKraftScalar):TKraftQuaternion;
var ThetaLenSquared,ThetaLen,s:TKraftScalar;
    DeltaQ:TKraftQuaternion;
    Theta:TKraftVector3;
begin
 Theta:=Vector3ScalarMul(Omega,DeltaTime*0.5);
 ThetaLenSquared:=Vector3LengthSquared(Theta);
 if (sqr(ThetaLenSquared)/24.0)<EPSILON then begin
  DeltaQ.w:=1.0-(ThetaLenSquared*0.5);
  s:=1.0-(ThetaLenSquared/6.0);
 end else begin
  ThetaLen:=sqrt(ThetaLenSquared);
  DeltaQ.w:=cos(ThetaLen);
  s:=sin(ThetaLen)/ThetaLen;
 end;
 DeltaQ.x:=Theta.x*s;
 DeltaQ.y:=Theta.y*s;
 DeltaQ.z:=Theta.z*s;
 result:=QuaternionMul(DeltaQ,q);
end;

function QuaternionSpin(const q:TKraftQuaternion;const Omega:TKraftVector3;const DeltaTime:TKraftScalar):TKraftQuaternion; overload;
var wq:TKraftQuaternion;
begin
 wq.x:=Omega.x*DeltaTime;
 wq.y:=Omega.y*DeltaTime;
 wq.z:=Omega.z*DeltaTime;
 wq.w:=0.0;
 result:=QuaternionTermNormalize(QuaternionAdd(q,QuaternionScalarMul(QuaternionMul(wq,q),0.5)));
end;

procedure QuaternionDirectSpin(var q:TKraftQuaternion;const Omega:TKraftVector3;const DeltaTime:TKraftScalar); overload;
var wq,tq:TKraftQuaternion;
begin
 wq.x:=Omega.x*DeltaTime;
 wq.y:=Omega.y*DeltaTime;
 wq.z:=Omega.z*DeltaTime;
 wq.w:=0.0;
 tq:=QuaternionAdd(q,QuaternionScalarMul(QuaternionMul(wq,q),0.5));
 q:=QuaternionTermNormalize(tq);
end;

function QuaternionFromToRotation(const FromDirection,ToDirection:TKraftVector3):TKraftQuaternion; {$ifdef caninline}inline;{$endif}
var t:TKraftVector3;
begin
 t:=Vector3Cross(Vector3Norm(FromDirection),Vector3Norm(ToDirection));
 result.x:=t.x;
 result.y:=t.y;
 result.z:=t.z;
 result.w:=sqrt((sqr(FromDirection.x)+sqr(FromDirection.y)+sqr(FromDirection.z))*
                (sqr(ToDirection.x)+sqr(ToDirection.y)+sqr(ToDirection.z)))+
               ((FromDirection.x*ToDirection.x)+(FromDirection.y*ToDirection.y)+(FromDirection.z*ToDirection.z));
end;


function AABBCost(const AABB:TKraftAABB):TKraftScalar; {$ifdef caninline}inline;{$endif}
begin
// result:=(AABB.Max.x-AABB.Min.x)+(AABB.Max.y-AABB.Min.y)+(AABB.Max.z-AABB.Min.z); // Manhattan distance
 result:=(AABB.Max.x-AABB.Min.x)*(AABB.Max.y-AABB.Min.y)*(AABB.Max.z-AABB.Min.z); // Volume
end;
                    
function AABBCombine(const AABB,WithAABB:TKraftAABB):TKraftAABB; {$ifdef caninline}inline;{$endif}
begin
 result.Min.x:=Min(AABB.Min.x,WithAABB.Min.x);
 result.Min.y:=Min(AABB.Min.y,WithAABB.Min.y);
 result.Min.z:=Min(AABB.Min.z,WithAABB.Min.z);
 result.Max.x:=Max(AABB.Max.x,WithAABB.Max.x);
 result.Max.y:=Max(AABB.Max.y,WithAABB.Max.y);
 result.Max.z:=Max(AABB.Max.z,WithAABB.Max.z);
end;

function AABBCombineVector3(const AABB:TKraftAABB;v:TKraftVector3):TKraftAABB; {$ifdef caninline}inline;{$endif}
begin
 result.Min.x:=Min(AABB.Min.x,v.x);
 result.Min.y:=Min(AABB.Min.y,v.y);
 result.Min.z:=Min(AABB.Min.z,v.z);
 result.Max.x:=Max(AABB.Max.x,v.x);
 result.Max.y:=Max(AABB.Max.y,v.y);
 result.Max.z:=Max(AABB.Max.z,v.z);
end;

function AABBIntersect(const AABB,WithAABB:TKraftAABB;Threshold:TKraftScalar=EPSILON):boolean; {$ifdef caninline}inline;{$endif}
begin
 result:=(((AABB.Max.x+Threshold)>=(WithAABB.Min.x-Threshold)) and ((AABB.Min.x-Threshold)<=(WithAABB.Max.x+Threshold))) and
         (((AABB.Max.y+Threshold)>=(WithAABB.Min.y-Threshold)) and ((AABB.Min.y-Threshold)<=(WithAABB.Max.y+Threshold))) and
         (((AABB.Max.z+Threshold)>=(WithAABB.Min.z-Threshold)) and ((AABB.Min.z-Threshold)<=(WithAABB.Max.z+Threshold)));
end;

function AABBContains(const InAABB,AABB:TKraftAABB):boolean; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=((InAABB.Min.x-EPSILON)<=(AABB.Min.x+EPSILON)) and ((InAABB.Min.y-EPSILON)<=(AABB.Min.y+EPSILON)) and ((InAABB.Min.z-EPSILON)<=(AABB.Min.z+EPSILON)) and
         ((InAABB.Max.x+EPSILON)>=(AABB.Min.x+EPSILON)) and ((InAABB.Max.y+EPSILON)>=(AABB.Min.y+EPSILON)) and ((InAABB.Max.z+EPSILON)>=(AABB.Min.z+EPSILON)) and
         ((InAABB.Min.x-EPSILON)<=(AABB.Max.x-EPSILON)) and ((InAABB.Min.y-EPSILON)<=(AABB.Max.y-EPSILON)) and ((InAABB.Min.z-EPSILON)<=(AABB.Max.z-EPSILON)) and
         ((InAABB.Max.x+EPSILON)>=(AABB.Max.x-EPSILON)) and ((InAABB.Max.y+EPSILON)>=(AABB.Max.y-EPSILON)) and ((InAABB.Max.z+EPSILON)>=(AABB.Max.z-EPSILON));
end;

function AABBContains(const AABB:TKraftAABB;Vector:TKraftVector3):boolean; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=((Vector.x>=(AABB.Min.x-EPSILON)) and (Vector.x<=(AABB.Max.x+EPSILON))) and
         ((Vector.y>=(AABB.Min.y-EPSILON)) and (Vector.y<=(AABB.Max.y+EPSILON))) and
         ((Vector.z>=(AABB.Min.z-EPSILON)) and (Vector.z<=(AABB.Max.z+EPSILON)));
end;

function AABBTransform(const DstAABB:TKraftAABB;const Transform:TKraftMatrix4x4):TKraftAABB; {$ifdef caninline}inline;{$endif}
var i,j:longint;
    a,b:TKraftScalar;
begin
 result.Min:=Vector3(Transform[3,0],Transform[3,1],Transform[3,2]);
 result.Max:=result.Min;
 for i:=0 to 2 do begin
  for j:=0 to 2 do begin
   a:=Transform[j,i]*DstAABB.Min.xyz[j];
   b:=Transform[j,i]*DstAABB.Max.xyz[j];
   if a<b then begin
    result.Min.xyz[i]:=result.Min.xyz[i]+a;
    result.Max.xyz[i]:=result.Max.xyz[i]+b;
   end else begin
    result.Min.xyz[i]:=result.Min.xyz[i]+b;
    result.Max.xyz[i]:=result.Max.xyz[i]+a;
   end;
  end;
 end;
end;

function AABBRayIntersection(const AABB:TKraftAABB;const Origin,Direction:TKraftVector3;var Time:TKraftScalar):boolean; overload; {$ifdef caninline}inline;{$endif}
var InvDirection,a,b,AABBMin,AABBMax:TKraftVector3;
    TimeMin,TimeMax:TKraftScalar;
begin
 if Direction.x<>0.0 then begin
  InvDirection.x:=1.0/Direction.x;
 end else begin
  InvDirection.x:=0.0;
 end;
 if Direction.y<>0.0 then begin
  InvDirection.y:=1.0/Direction.y;
 end else begin
  InvDirection.y:=0.0;
 end;
 if Direction.z<>0.0 then begin
  InvDirection.z:=1.0/Direction.z;
 end else begin
  InvDirection.z:=0.0;
 end;
 a.x:=(AABB.Min.x-Origin.x)*InvDirection.x;
 a.y:=(AABB.Min.y-Origin.y)*InvDirection.y;
 a.z:=(AABB.Min.z-Origin.z)*InvDirection.z;
 b.x:=(AABB.Max.x-Origin.x)*InvDirection.x;
 b.y:=(AABB.Max.y-Origin.y)*InvDirection.y;
 b.z:=(AABB.Max.z-Origin.z)*InvDirection.z;
 if a.x<b.x then begin
  AABBMin.x:=a.x;
  AABBMax.x:=b.x;
 end else begin
  AABBMin.x:=b.x;
  AABBMax.x:=a.x;
 end;
 if a.y<b.y then begin
  AABBMin.y:=a.y;
  AABBMax.y:=b.y;
 end else begin
  AABBMin.y:=b.y;
  AABBMax.y:=a.y;
 end;
 if a.z<b.z then begin
  AABBMin.z:=a.z;
  AABBMax.z:=b.z;
 end else begin
  AABBMin.z:=b.z;
  AABBMax.z:=a.z;
 end;
 if AABBMin.x<AABBMin.y then begin
  if AABBMin.x<AABBMin.z then begin
   TimeMin:=AABBMin.x;
  end else begin
   TimeMin:=AABBMin.z;
  end;
 end else begin
  if AABBMin.y<AABBMin.z then begin
   TimeMin:=AABBMin.y;
  end else begin
   TimeMin:=AABBMin.z;
  end;
 end;
 if AABBMax.x>AABBMax.y then begin
  if AABBMax.x>AABBMax.z then begin
   TimeMax:=AABBMax.x;
  end else begin
   TimeMax:=AABBMax.z;
  end;
 end else begin
  if AABBMax.y>AABBMax.z then begin
   TimeMax:=AABBMax.y;
  end else begin
   TimeMax:=AABBMax.z;
  end;
 end;
 if (TimeMax<0) or (TimeMin>TimeMax) then begin
  Time:=TimeMax;
  result:=false;
 end else begin
  Time:=TimeMin;
  result:=true;
 end;
end;

function AABBRayIntersect(const AABB:TKraftAABB;const Origin,Direction:TKraftVector3):boolean; {$ifdef caninline}inline;{$endif}
var Center,BoxExtents,Diff:TKraftVector3;
begin
 Center:=Vector3ScalarMul(Vector3Add(AABB.Min,AABB.Max),0.5);
 BoxExtents:=Vector3Sub(Center,AABB.Min);
 Diff:=Vector3Sub(Origin,Center);
 result:=not ((((abs(Diff.x)>BoxExtents.x) and ((Diff.x*Direction.x)>=0)) or
               ((abs(Diff.y)>BoxExtents.y) and ((Diff.y*Direction.y)>=0)) or
               ((abs(Diff.z)>BoxExtents.z) and ((Diff.z*Direction.z)>=0))) or
              ((abs((Direction.y*Diff.z)-(Direction.z*Diff.y))>((BoxExtents.y*abs(Direction.z))+(BoxExtents.z*abs(Direction.y)))) or
               (abs((Direction.z*Diff.x)-(Direction.x*Diff.z))>((BoxExtents.x*abs(Direction.z))+(BoxExtents.z*abs(Direction.x)))) or
               (abs((Direction.x*Diff.y)-(Direction.y*Diff.x))>((BoxExtents.x*abs(Direction.y))+(BoxExtents.y*abs(Direction.x))))));
end;

function SphereFromAABB(const AABB:TKraftAABB):TKraftSphere; {$ifdef caninline}inline;{$endif}
begin
 result.Center:=Vector3Avg(AABB.Min,AABB.Max);
 result.Radius:=Vector3Dist(AABB.Min,AABB.Max)*0.5;
end;

function RayIntersectTriangle(const RayOrigin,RayDirection,v0,v1,v2:TKraftVector3;var Time,u,v:TKraftScalar):boolean; overload;
var e0,e1,p,t,q:TKraftVector3;
    Determinant,InverseDeterminant:TKraftScalar;
begin
 result:=false;

 e0.x:=v1.x-v0.x;
 e0.y:=v1.y-v0.y;
 e0.z:=v1.z-v0.z;
 e1.x:=v2.x-v0.x;
 e1.y:=v2.y-v0.y;
 e1.z:=v2.z-v0.z;

 p.x:=(RayDirection.y*e1.z)-(RayDirection.z*e1.y);
 p.y:=(RayDirection.z*e1.x)-(RayDirection.x*e1.z);
 p.z:=(RayDirection.x*e1.y)-(RayDirection.y*e1.x);

 Determinant:=(e0.x*p.x)+(e0.y*p.y)+(e0.z*p.z);
 if Determinant<EPSILON then begin
  exit;
 end;

 t.x:=RayOrigin.x-v0.x;
 t.y:=RayOrigin.y-v0.y;
 t.z:=RayOrigin.z-v0.z;

 u:=(t.x*p.x)+(t.y*p.y)+(t.z*p.z);
 if (u<0.0) or (u>Determinant) then begin
  exit;
 end;

 q.x:=(t.y*e0.z)-(t.z*e0.y);
 q.y:=(t.z*e0.x)-(t.x*e0.z);
 q.z:=(t.x*e0.y)-(t.y*e0.x);

 v:=(RayDirection.x*q.x)+(RayDirection.y*q.y)+(RayDirection.z*q.z);
 if (v<0.0) or ((u+v)>Determinant) then begin
  exit;
 end;

 Time:=(e1.x*q.x)+(e1.y*q.y)+(e1.z*q.z);
 if abs(Determinant)<EPSILON then begin
  Determinant:=0.01;
 end;
 InverseDeterminant:=1.0/Determinant;
 Time:=Time*InverseDeterminant;
 u:=u*InverseDeterminant;
 v:=v*InverseDeterminant;

 result:=true;
end;

function IsPointsSameSide(const p0,p1,Origin,Direction:TKraftVector3):boolean; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Vector3Dot(Vector3Cross(Direction,Vector3Sub(p0,Origin)),Vector3Cross(Direction,Vector3Sub(p1,Origin)))>=0.0;
end;

function PointInTriangle(const p0,p1,p2,Normal,p:TKraftVector3):boolean; overload; {$ifdef caninline}inline;{$endif}
var r0,r1,r2:TKraftScalar;
begin
 r0:=Vector3Dot(Vector3Cross(Vector3Sub(p1,p0),Normal),Vector3Sub(p,p0));
 r1:=Vector3Dot(Vector3Cross(Vector3Sub(p2,p1),Normal),Vector3Sub(p,p1));
 r2:=Vector3Dot(Vector3Cross(Vector3Sub(p0,p2),Normal),Vector3Sub(p,p2));
 result:=((r0>0.0) and (r1>0.0) and (r2>0.0)) or ((r0<=0.0) and (r1<=0.0) and (r2<=0.0));
end;

function PointInTriangle(const p0,p1,p2,p:TKraftVector3):boolean; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=IsPointsSameSide(p,p0,p1,Vector3Sub(p2,p1)) and
         IsPointsSameSide(p,p1,p0,Vector3Sub(p2,p0)) and
         IsPointsSameSide(p,p2,p0,Vector3Sub(p1,p0));
end;

function SquaredDistanceFromPointToTriangle(const p,a,b,c:TKraftVector3):TKraftScalar; overload;
var ab,ac,bc,pa,pb,pc,ap,bp,cp,n:TKraftVector3;
    snom,sdenom,tnom,tdenom,unom,udenom,vc,vb,va,u,v,w:TKraftScalar;
begin

 ab.x:=b.x-a.x;
 ab.y:=b.y-a.y;
 ab.z:=b.z-a.z;

 ac.x:=c.x-a.x;
 ac.y:=c.y-a.y;
 ac.z:=c.z-a.z;

 bc.x:=c.x-b.x;
 bc.y:=c.y-b.y;
 bc.z:=c.z-b.z;

 pa.x:=p.x-a.x;
 pa.y:=p.y-a.y;
 pa.z:=p.z-a.z;

 pb.x:=p.x-b.x;
 pb.y:=p.y-b.y;
 pb.z:=p.z-b.z;

 pc.x:=p.x-c.x;
 pc.y:=p.y-c.y;
 pc.z:=p.z-c.z;

 // Determine the parametric position s for the projection of P onto AB (i.e. PPU2 = A+s*AB, where
 // s = snom/(snom+sdenom), and then parametric position t for P projected onto AC
 snom:=(ab.x*pa.x)+(ab.y*pa.y)+(ab.z*pa.z);
 sdenom:=(pb.x*(a.x-b.x))+(pb.y*(a.y-b.y))+(pb.z*(a.z-b.z));
 tnom:=(ac.x*pa.x)+(ac.y*pa.y)+(ac.z*pa.z);
 tdenom:=(pc.x*(a.x-c.x))+(pc.y*(a.y-c.y))+(pc.z*(a.z-c.z));
 if (snom<=0.0) and (tnom<=0.0) then begin
  // Vertex voronoi region hit early out
  result:=sqr(a.x-p.x)+sqr(a.y-p.y)+sqr(a.z-p.z);
  exit;
 end;

 // Parametric position u for P projected onto BC
 unom:=(bc.x*pb.x)+(bc.y*pb.y)+(bc.z*pb.z);
 udenom:=(pc.x*(b.x-c.x))+(pc.y*(b.y-c.y))+(pc.z*(b.z-c.z));
 if (sdenom<=0.0) and (unom<=0.0) then begin
  // Vertex voronoi region hit early out
  result:=sqr(b.x-p.x)+sqr(b.y-p.y)+sqr(b.z-p.z);
  exit;
 end;
 if (tdenom<=0.0) and (udenom<=0.0) then begin
  // Vertex voronoi region hit early out
  result:=sqr(c.x-p.x)+sqr(c.y-p.y)+sqr(c.z-p.z);
  exit;
 end;

 // Determine if P is outside (or on) edge AB by finding the area formed by vectors PA, PB and
 // the triangle normal. A scalar triple product is used. P is outside (or on) AB if the triple
 // scalar product [N PA PB] <= 0
 n.x:=(ab.y*ac.z)-(ab.z*ac.y);
 n.y:=(ab.z*ac.x)-(ab.x*ac.z);
 n.z:=(ab.x*ac.y)-(ab.y*ac.x);
 ap.x:=a.x-p.x;
 ap.y:=a.y-p.y;
 ap.z:=a.z-p.z;
 bp.x:=b.x-p.x;
 bp.y:=b.y-p.y;
 bp.z:=b.z-p.z;
 vc:=(n.x*((ap.y*bp.z)-(ap.z*bp.y)))+(n.y*((ap.z*bp.x)-(ap.x*bp.z)))+(n.z*((ap.x*bp.y)-(ap.y*bp.x)));

 // If P is outside of AB (signed area <= 0) and within voronoi feature region, then return
 // projection of P onto AB
 if (vc<=0.0) and (snom>=0.0) and (sdenom>=0.0) then begin
  u:=snom/(snom+sdenom);
  result:=sqr((a.x+(ab.x*u))-p.x)+sqr((a.y+(ab.y*u))-p.y)+sqr((a.z+(ab.z*u))-p.z);
  exit;
 end;

 // Repeat the same test for P onto BC
 cp.x:=c.x-p.x;
 cp.y:=c.y-p.y;
 cp.z:=c.z-p.z;
 va:=(n.x*((bp.y*cp.z)-(bp.z*cp.y)))+(n.y*((bp.z*cp.x)-(bp.x*cp.z)))+(n.z*((bp.x*cp.y)-(bp.y*cp.x)));
 if (va<=0.0) and (unom>=0.0) and (udenom>=0.0) then begin
  v:=unom/(unom+udenom);
  result:=sqr((b.x+(bc.x*v))-p.x)+sqr((b.y+(bc.y*v))-p.y)+sqr((b.z+(bc.z*v))-p.z);
  exit;
 end;

 // Repeat the same test for P onto CA
 vb:=(n.x*((cp.y*ap.z)-(cp.z*ap.y)))+(n.y*((cp.z*ap.x)-(cp.x*ap.z)))+(n.z*((cp.x*ap.y)-(cp.y*ap.x)));
 if (vb<=0.0) and (tnom>=0.0) and (tdenom>=0.0) then begin
  w:=tnom/(tnom+tdenom);
  result:=sqr((a.x+(ac.x*w))-p.x)+sqr((a.y+(ac.y*w))-p.y)+sqr((a.z+(ac.z*w))-p.z);
  exit;
 end;

 // P must project onto inside face. Find closest point using the barycentric coordinates
 w:=1.0/(va+vb+vc);
 u:=va*w;
 v:=vb*w;
 w:=(1.0-u)-v;

 result:=sqr(((a.x*u)+(b.x*v)+(c.x*w))-p.x)+sqr(((a.y*u)+(b.y*v)+(c.y*w))-p.y)+sqr(((a.z*u)+(b.z*v)+(c.z*w))-p.z);

end;

function SegmentSqrDistance(const FromVector,ToVector,p:TKraftVector3;out Nearest:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
var t,DotUV:TKraftScalar;
    Diff,v:TKraftVector3;
begin
 Diff:=Vector3Sub(p,FromVector);
 v:=Vector3Sub(ToVector,FromVector);
 t:=Vector3Dot(v,Diff);
 if t>0.0 then begin
  DotUV:=Vector3LengthSquared(v);
  if t<DotUV then begin
   t:=t/DotUV;
   Diff:=Vector3Sub(Diff,Vector3ScalarMul(v,t));
  end else begin
   t:=1;
   Diff:=Vector3Sub(Diff,v);
  end;
 end else begin
  t:=0.0;
 end;
 Nearest:=Vector3Lerp(FromVector,ToVector,t);
 result:=Vector3LengthSquared(Diff);
end;

function ClipSegmentToPlane(const Plane:TKraftPlane;var p0,p1:TKraftVector3):boolean;
var d0,d1:TKraftScalar;
    o0,o1:boolean;
begin
 d0:=PlaneVectorDistance(Plane,p0);
 d1:=PlaneVectorDistance(Plane,p1);
 o0:=d0<0.0;
 o1:=d1<0.0;
 if o0 and o1 then begin
  // Both points are below which means that the whole line segment is below => return false
  result:=false;
 end else begin
  // At least one point is above or in the plane which means that the line segment is above => return true
  if (o0<>o1) and (abs(d0-d1)>EPSILON) then begin
   if o0 then begin
    // p1 is above or in the plane which means that the line segment is above => clip l0
    p0:=Vector3Add(p0,Vector3ScalarMul(Vector3Sub(p1,p0),d0/(d0-d1)));
   end else begin
    // p0 is above or in the plane which means that the line segment is above => clip l1
    p1:=Vector3Add(p0,Vector3ScalarMul(Vector3Sub(p1,p0),d0/(d0-d1)));
   end;
  end else begin
   // Near parallel case => no clipping
  end;
  result:=true;
 end;
end;

function SegmentSegmentDistanceSq(out t0,t1:single;seg0,seg1:TKraftRelativeSegment):single;
var kDiff:TKraftVector3;
    fA00,fA01,fA11,fB0,fC,fDet,fB1,fS,fT,fSqrDist,fTmp,fInvDet:TKraftScalar;
begin
 kDiff:=Vector3Sub(seg0.Origin,seg1.Origin);
 fA00:=Vector3LengthSquared(seg0.Delta);
 fA01:=-Vector3Dot(seg0.Delta,seg1.Delta);
 fA11:=Vector3LengthSquared(seg1.Delta);
 fB0:=Vector3Dot(kDiff,seg0.Delta);
 fC:=Vector3LengthSquared(kDiff);
 fDet:=abs((fA00*fA11)-(fA01*fA01));
 if fDet>=EPSILON then begin
  // line segments are not parallel
  fB1:=-Vector3Dot(kDiff,seg1.Delta);
  fS:=(fA01*fB1)-(fA11*fB0);
  fT:=(fA01*fB0)-(fA00*fB1);
  if fS>=0.0 then begin
   if fS<=fDet then begin
    if fT>=0.0 then begin
     if fT<=fDet then begin // region 0 (interior)
      // minimum at two interior points of 3D lines
      fInvDet:=1.0/fDet;
      fS:=fS*fInvDet;
      fT:=fT*fInvDet;
      fSqrDist:=(fS*((fA00*fS)+(fA01*fT)+(2.0*fB0)))+(fT*((fA01*fS)+(fA11*fT)+(2.0*fB1)))+fC;
     end else begin // region 3 (side)
      fT:=1.0;
      fTmp:=fA01+fB0;
      if fTmp>=0.0 then begin
       fS:=0.0;
       fSqrDist:=fA11+(2.0*fB1)+fC;
      end else if (-fTmp)>=fA00 then begin
       fS:=1.0;
       fSqrDist:=fA00+fA11+fC+(2.0*(fB1+fTmp));
      end else begin
       fS:=-fTmp/fA00;
       fSqrDist:=fTmp*fS+fA11+(2.0*fB1)+fC;
      end;
     end;
    end else begin // region 7 (side)
     fT:=0.0;
     if fB0>=0.0 then begin
      fS:=0.0;
      fSqrDist:=fC;
     end else if (-fB0)>=fA00 then begin
      fS:=1.0;
      fSqrDist:=fA00+(2.0*fB0)+fC;
     end else begin
      fS:=(-fB0)/fA00;
      fSqrDist:=(fB0*fS)+fC;
     end;
    end;
   end else begin
    if fT>=0.0 then begin
     if fT<=fDet then begin // region 1 (side)
      fS:=1.0;
      fTmp:=fA01+fB1;
      if fTmp>=0.0 then begin
       fT:=0.0;
       fSqrDist:=fA00+(2.0*fB0)+fC;
      end else if (-fTmp)>=fA11 then begin
       fT:=1.0;
       fSqrDist:=fA00+fA11+fC+(2.0*(fB0+fTmp));
      end else begin
       fT:=(-fTmp)/fA11;
       fSqrDist:=(fTmp*fT)+fA00+(2.0*fB0)+fC;
      end;
     end else begin // region 2 (corner)
      fTmp:=fA01+fB0;
      if (-fTmp)<=fA00 then begin
       fT:=1.0;
       if fTmp>=0.0 then begin
        fS:=0.0;
        fSqrDist:=fA11+(2.0*fB1)+fC;
       end else begin
        fS:=(-fTmp)/fA00;
        fSqrDist:=(fTmp*fS)+fA11+(2.0*fB1)+fC;
       end;
      end else begin
       fS:=1.0;
       fTmp:=fA01+fB1;
       if fTmp>=0.0 then begin
        fT:=0.0;
        fSqrDist:=fA00+(2.0*fB0)+fC;
       end else if (-fTmp)>=fA11 then begin
        fT:=1.0;
        fSqrDist:=fA00+fA11+fC+(2.0*(fB0+fTmp));
       end else begin
        fT:=(-fTmp)/fA11;
        fSqrDist:=(fTmp*fT)+fA00+(2.0*fB0)+fC;
       end;
      end;
     end;
    end else begin // region 8 (corner)
     if (-fB0)<fA00 then begin
      fT:=0.0;
      if fB0>=0.0 then begin
       fS:=0.0;
       fSqrDist:=fC;
      end else begin
       fS:=(-fB0)/fA00;
       fSqrDist:=(fB0*fS)+fC;
      end;
     end else begin
      fS:=1.0;
      fTmp:=fA01+fB1;
      if fTmp>=0.0 then begin
       fT:=0.0;
       fSqrDist:=fA00+(2.0*fB0)+fC;
      end else if (-fTmp)>=fA11 then begin
       fT:=1.0;
       fSqrDist:=fA00+fA11+fC+(2.0*(fB0+fTmp));
      end else begin
       fT:=(-fTmp)/fA11;
       fSqrDist:=(fTmp*fT)+fA00+(2.0*fB0)+fC;
      end;
      end;
    end;
   end;
  end else begin
   if fT>=0.0 then begin
    if fT<=fDet then begin // region 5 (side)
     fS:=0.0;
     if fB1>=0.0 then begin
      fT:=0.0;
      fSqrDist:=fC;
     end else if (-fB1)>=fA11 then begin
      fT:=1.0;
      fSqrDist:=fA11+(2.0*fB1)+fC;
     end else begin
      fT:=(-fB1)/fA11;
      fSqrDist:=fB1*fT+fC;
     end
    end else begin // region 4 (corner)
     fTmp:=fA01+fB0;
     if fTmp<0.0 then begin
      fT:=1.0;
      if (-fTmp)>=fA00 then begin
       fS:=1.0;
       fSqrDist:=fA00+fA11+fC+(2.0*(fB1+fTmp));
      end else begin
       fS:=(-fTmp)/fA00;
       fSqrDist:=fTmp*fS+fA11+(2.0*fB1)+fC;
      end;
     end else begin
      fS:=0.0;
      if fB1>=0.0 then begin
       fT:=0.0;
       fSqrDist:=fC;
      end else if (-fB1)>=fA11 then begin
       fT:=1.0;
       fSqrDist:=fA11+(2.0*fB1)+fC;
      end else begin
       fT:=(-fB1)/fA11;
       fSqrDist:=(fB1*fT)+fC;
      end;
     end;
    end;
   end else begin // region 6 (corner)
    if fB0<0.0 then begin
     fT:=0.0;
     if (-fB0)>=fA00 then begin
      fS:=1.0;
      fSqrDist:=fA00+(2.0*fB0)+fC;
     end else begin
      fS:=(-fB0)/fA00;
      fSqrDist:=(fB0*fS)+fC;
     end;
    end else begin
     fS:=0.0;
     if fB1>=0.0 then begin
      fT:=0.0;
      fSqrDist:=fC;
     end else if (-fB1)>=fA11 then begin
      fT:=1.0;
      fSqrDist:=fA11+(2.0*fB1)+fC;
     end else begin
      fT:=(-fB1)/fA11;
      fSqrDist:=(fB1*fT)+fC;
     end;
    end;
   end;
  end;
 end else begin // line segments are parallel
  if fA01>0.0 then begin // direction vectors form an obtuse angle
   if fB0>=0.0 then begin
    fS:=0.0;
    fT:=0.0;
    fSqrDist:=fC;
   end else if (-fB0)<=fA00 then begin
    fS:=(-fB0)/fA00;
    fT:=0.0;
    fSqrDist:=(fB0*fS)+fC;
   end else begin
    fB1:=-Vector3Dot(kDiff,seg1.Delta);
    fS:=1.0;
    fTmp:=fA00+fB0;
    if (-fTmp)>=fA01 then begin
     fT:=1.0;
     fSqrDist:=fA00+fA11+fC+(2.0*(fA01+fB0+fB1));
    end else begin
     fT:=(-fTmp)/fA01;
     fSqrDist:=fA00+(2.0*fB0)+fC+(fT*((fA11*fT)+(2.0*(fA01+fB1))));
    end;
   end;
  end else begin // direction vectors form an acute angle
   if (-fB0)>=fA00 then begin
    fS:=1.0;
    fT:=0.0;
    fSqrDist:=fA00+(2.0*fB0)+fC;
   end else if fB0<=0.0 then begin
    fS:=(-fB0)/fA00;
    fT:=0.0;
    fSqrDist:=(fB0*fS)+fC;
   end else begin
    fB1:=-Vector3Dot(kDiff,seg1.Delta);
    fS:=0.0;
    if fB0>=(-fA01) then begin
     fT:=1.0;
     fSqrDist:=fA11+(2.0*fB1)+fC;
    end else begin
     fT:=(-fB0)/fA01;
     fSqrDist:=fC+(fT*((2.0)*fB1)+(fA11*fT));
    end;
   end;
  end;
 end;
 t0:=fS;
 t1:=fT;
 result:=abs(fSqrDist);
end;

procedure SIMDSegment(out Segment:TKraftSegment;const p0,p1:TKraftVector3); overload;
begin
 Segment.Points[0]:=p0;
 Segment.Points[1]:=p1;
end;

function SIMDSegment(const p0,p1:TKraftVector3):TKraftSegment; overload;
begin
 result.Points[0]:=p0;
 result.Points[1]:=p1;
end;

function SIMDSegmentSquaredDistanceTo(const Segment:TKraftSegment;const p:TKraftVector3):TKraftScalar;
var pq,pp:TKraftVector3;
    e,f:TKraftScalar;
begin
 pq:=Vector3Sub(Segment.Points[1],Segment.Points[0]);
 pp:=Vector3Sub(p,Segment.Points[0]);
 e:=Vector3Dot(pp,pq);
 if e<=0.0 then begin
  result:=Vector3LengthSquared(pp);
 end else begin
  f:=Vector3LengthSquared(pq);
  if e<f then begin
   result:=Vector3LengthSquared(pp)-(sqr(e)/f);
  end else begin
   result:=Vector3LengthSquared(Vector3Sub(p,Segment.Points[1]));
  end;
 end;
end;

procedure SIMDSegmentClosestPointTo(const Segment:TKraftSegment;const p:TKraftVector3;out Time:TKraftScalar;out ClosestPoint:TKraftVector3);
var u,v:TKraftVector3;
begin
 u:=Vector3Sub(Segment.Points[1],Segment.Points[0]);
 v:=Vector3Sub(p,Segment.Points[0]);
 Time:=Vector3Dot(u,v)/Vector3LengthSquared(u);
 if Time<=0.0 then begin
  ClosestPoint:=Segment.Points[0];
 end else if Time>=1.0 then begin
  ClosestPoint:=Segment.Points[1];
 end else begin
  ClosestPoint:=Vector3Add(Vector3ScalarMul(Segment.Points[0],1.0-Time),Vector3ScalarMul(Segment.Points[1],Time));
 end;
end;

procedure SIMDSegmentTransform(out OutputSegment:TKraftSegment;const Segment:TKraftSegment;const Transform:TKraftMatrix4x4); overload;
begin
 OutputSegment.Points[0]:=Vector3TermMatrixMul(Segment.Points[0],Transform);
 OutputSegment.Points[1]:=Vector3TermMatrixMul(Segment.Points[1],Transform);
end;

function SIMDSegmentTransform(const Segment:TKraftSegment;const Transform:TKraftMatrix4x4):TKraftSegment; overload;
begin
 result.Points[0]:=Vector3TermMatrixMul(Segment.Points[0],Transform);
 result.Points[1]:=Vector3TermMatrixMul(Segment.Points[1],Transform);
end;

procedure SIMDSegmentClosestPoints(const SegmentA,SegmentB:TKraftSegment;out TimeA:TKraftScalar;out ClosestPointA:TKraftVector3;out TimeB:TKraftScalar;out ClosestPointB:TKraftVector3);
var dA,dB,r:TKraftVector3;
    a,b,c,{d,}e,f,Denominator,aA,aB,bA,bB:TKraftScalar;
begin
 dA:=Vector3Sub(SegmentA.Points[1],SegmentA.Points[0]);
 dB:=Vector3Sub(SegmentB.Points[1],SegmentB.Points[0]);
 r:=Vector3Sub(SegmentA.Points[0],SegmentB.Points[0]);
 a:=Vector3LengthSquared(dA);
 e:=Vector3LengthSquared(dB);
 f:=Vector3Dot(dB,r);
 if (a<EPSILON) and (e<EPSILON) then begin
  // segment a and b are both points
  TimeA:=0.0;
  TimeB:=0.0;
  ClosestPointA:=SegmentA.Points[0];
  ClosestPointB:=SegmentB.Points[0];
 end else begin
  if a<EPSILON then begin
   // segment a is a point
	 TimeA:=0.0;
   TimeB:=f/e;
   if TimeB<0.0 then begin
    TimeB:=0.0;
   end else if TimeB>1.0 then begin
    TimeB:=1.0;
   end;
  end else begin
   c:=Vector3Dot(dA,r);
   if e<EPSILON then begin
		// segment b is a point
    TimeA:=-(c/a);
    if TimeA<0.0 then begin
     TimeA:=0.0;
    end else if TimeA>1.0 then begin
     TimeA:=1.0;
    end;
    TimeB:=0.0;
	 end else begin
    b:=Vector3Dot(dA,dB);
    Denominator:=(a*e)-sqr(b);
		if Denominator<EPSILON then begin
     // segments are parallel
     aA:=Vector3Dot(dB,SegmentA.Points[0]);
     aB:=Vector3Dot(dB,SegmentA.Points[1]);
     bA:=Vector3Dot(dB,SegmentB.Points[0]);
     bB:=Vector3Dot(dB,SegmentB.Points[1]);
     if (aA<=bA) and (aB<=bA) then begin
			// segment A is completely "before" segment B
      if aB>aA then begin
       TimeA:=1.0;
      end else begin
       TimeA:=0.0;
      end;
      TimeB:=0.0;
     end else if (aA>=bB) and (aB>=bB) then begin
      // segment B is completely "before" segment A
      if aB>aA then begin
       TimeA:=0.0;
      end else begin
       TimeA:=1.0;
      end;
      TimeB:=1.0;
     end else begin
      // segments A and B overlap, use midpoint of shared length
			if aA>aB then begin
       f:=aA;
       aA:=aB;
       aB:=f;
      end;
      f:=(Min(aB,bB)+Max(aA,bA))*0.5;
      TimeB:=(f-bA)/e;
      ClosestPointB:=Vector3Add(SegmentB.Points[0],Vector3ScalarMul(dB,TimeB));
      SIMDSegmentClosestPointTo(SegmentA,ClosestPointB,TimeB,ClosestPointA);
      exit;
     end;
    end	else begin
     // general case
     TimeA:=((b*f)-(c*e))/Denominator;
     if TimeA<0.0 then begin
      TimeA:=0.0;
     end else if TimeA>1.0 then begin
      TimeA:=1.0;
     end;
     TimeB:=((b*TimeA)+f)/e;
     if TimeB<0.0 then begin
      TimeB:=0.0;
      TimeA:=-(c/a);
      if TimeA<0.0 then begin
       TimeA:=0.0;
      end else if TimeA>1.0 then begin
       TimeA:=1.0;
      end;
     end else if TimeB>1.0 then begin
      TimeB:=1.0;
      TimeA:=(b-c)/a;
      if TimeA<0.0 then begin
       TimeA:=0.0;
      end else if TimeA>1.0 then begin
       TimeA:=1.0;
      end;
     end;
    end;
   end;
  end;
  ClosestPointA:=Vector3Add(SegmentA.Points[0],Vector3ScalarMul(dA,TimeA));
  ClosestPointB:=Vector3Add(SegmentB.Points[0],Vector3ScalarMul(dB,TimeB));
 end;
end;

function SIMDSegmentIntersect(const SegmentA,SegmentB:TKraftSegment;out TimeA,TimeB:TKraftScalar;out IntersectionPoint:TKraftVector3):boolean;
var PointA:TKraftVector3;
begin
 SIMDSegmentClosestPoints(SegmentA,SegmentB,TimeA,PointA,TimeB,IntersectionPoint);
 result:=Vector3DistSquared(PointA,IntersectionPoint)<EPSILON;
end;

function SIMDTriangleContains(const Triangle:TKraftTriangle;const p:TKraftVector3):boolean;
var vA,vB,vC:TKraftVector3;
    dAB,dAC,dBC:TKraftScalar;
begin
 vA:=Vector3Sub(Triangle.Points[0],p);
 vB:=Vector3Sub(Triangle.Points[1],p);
 vC:=Vector3Sub(Triangle.Points[2],p);
 dAB:=Vector3Dot(vA,vB);
 dAC:=Vector3Dot(vA,vC);
 dBC:=Vector3Dot(vB,vC);
 if ((dBC*dAC)-(Vector3LengthSquared(vC)*dAB))<0.0 then begin
  result:=false;
 end else begin
  result:=((dAB*dBC)-(dAC*Vector3LengthSquared(vB)))>=0.0;
 end;
end;

function SIMDTriangleIntersect(const Triangle:TKraftTriangle;const Segment:TKraftSegment;out Time:TKraftScalar;out IntersectionPoint:TKraftVector3):boolean;
var Switched:boolean;
    d,t,v,w:TKraftScalar;
    vAB,vAC,pBA,vApA,e,n:TKraftVector3;
    s:TKraftSegment;
begin

 result:=false;

 Time:=NaN;

 IntersectionPoint:=Vector3Origin;

 Switched:=false;

 vAB:=Vector3Sub(Triangle.Points[1],Triangle.Points[0]);
 vAC:=Vector3Sub(Triangle.Points[2],Triangle.Points[0]);

 pBA:=Vector3Sub(Segment.Points[0],Segment.Points[1]);

 n:=Vector3Cross(vAB,vAC);

 d:=Vector3Dot(n,pBA);

 if abs(d)<EPSILON then begin
  exit; // segment is parallel
 end else if d<0.0 then begin
  s.Points[0]:=Segment.Points[1];
  s.Points[1]:=Segment.Points[0];
  Switched:=true;
  pBA:=Vector3Sub(s.Points[0],s.Points[1]);
  d:=-d;
 end else begin
  s:=Segment;
 end;

 vApA:=Vector3Sub(s.Points[0],Triangle.Points[0]);
 t:=Vector3Dot(n,vApA);
 e:=Vector3Cross(pBA,vApA);

 v:=Vector3Dot(vAC,e);
 if (v<0.0) or (v>d) then begin
  exit; // intersects outside triangle
 end;

 w:=-Vector3Dot(vAB,e);
 if (w<0.0) or ((v+w)>d) then begin
  exit; // intersects outside triangle
 end;

 d:=1.0/d;
 t:=t*d;
 v:=v*d;
 w:=w*d;
 Time:=t;

 IntersectionPoint:=Vector3Add(Triangle.Points[0],Vector3Add(Vector3ScalarMul(vAB,v),Vector3ScalarMul(vAC,w)));

 if Switched then begin
	Time:=1.0-Time;
 end;

 result:=(Time>=0.0) and (Time<=1.0);
end;

function SIMDTriangleClosestPointTo(const Triangle:TKraftTriangle;const Point:TKraftVector3;out ClosestPoint:TKraftVector3):boolean; overload;
var u,v,w,d1,d2,d3,d4,d5,d6,Denominator:TKraftScalar;
    vAB,vAC,vAp,vBp,vCp:TKraftVector3;
begin
 result:=false;

 vAB:=Vector3Sub(Triangle.Points[1],Triangle.Points[0]);
 vAC:=Vector3Sub(Triangle.Points[2],Triangle.Points[0]);
 vAp:=Vector3Sub(Point,Triangle.Points[0]);

 d1:=Vector3Dot(vAB,vAp);
 d2:=Vector3Dot(vAC,vAp);
 if (d1<=0.0) and (d2<=0.0) then begin
	ClosestPoint:=Triangle.Points[0]; // closest point is vertex A
	exit;
 end;

 vBp:=Vector3Sub(Point,Triangle.Points[1]);
 d3:=Vector3Dot(vAB,vBp);
 d4:=Vector3Dot(vAC,vBp);
 if (d3>=0.0) and (d4<=d3) then begin
	ClosestPoint:=Triangle.Points[1]; // closest point is vertex B
	exit;
 end;
                                  
 w:=(d1*d4)-(d3*d2);
 if (w<=0.0) and (d1>=0.0) and (d3<=0.0) then begin
 	// closest point is along edge 1-2
	ClosestPoint:=Vector3Add(Triangle.Points[0],Vector3ScalarMul(vAB,d1/(d1-d3)));
  exit;
 end;

 vCp:=Vector3Sub(Point,Triangle.Points[2]);
 d5:=Vector3Dot(vAB,vCp);
 d6:=Vector3Dot(vAC,vCp);
 if (d6>=0.0) and (d5<=d6) then begin
	ClosestPoint:=Triangle.Points[2]; // closest point is vertex C
	exit;
 end;

 v:=(d5*d2)-(d1*d6);
 if (v<=0.0) and (d2>=0.0) and (d6<=0.0) then begin
 	// closest point is along edge 1-3
	ClosestPoint:=Vector3Add(Triangle.Points[0],Vector3ScalarMul(vAC,d2/(d2-d6)));
  exit;
 end;

 u:=(d3*d6)-(d5*d4);
 if (u<=0.0) and ((d4-d3)>=0.0) and ((d5-d6)>=0.0) then begin
	// closest point is along edge 2-3
	ClosestPoint:=Vector3Add(Triangle.Points[1],Vector3ScalarMul(Vector3Sub(Triangle.Points[2],Triangle.Points[1]),(d4-d3)/((d4-d3)+(d5-d6))));
  exit;
 end;

 Denominator:=1.0/(u+v+w);

 ClosestPoint:=Vector3Add(Triangle.Points[0],Vector3Add(Vector3ScalarMul(vAB,v*Denominator),Vector3ScalarMul(vAC,w*Denominator)));

 result:=true;
end;

function SIMDTriangleClosestPointTo(const Triangle:TKraftTriangle;const Segment:TKraftSegment;out Time:TKraftScalar;out ClosestPointOnSegment,ClosestPointOnTriangle:TKraftVector3):boolean; overload;
var MinDist,dtri,d1,d2,sa,sb,dist:TKraftScalar;
    pAInside,pBInside:boolean;
    pa,pb:TKraftVector3;
    Edge:TKraftSegment;
begin

 result:=SIMDTriangleIntersect(Triangle,Segment,Time,ClosestPointOnTriangle);

 if result then begin

 	// segment intersects triangle
  ClosestPointOnSegment:=ClosestPointOnTriangle;

 end else begin

  MinDist:=MAX_SCALAR;

  ClosestPointOnSegment:=Vector3Origin;

  dtri:=Vector3Dot(Triangle.Normal,Triangle.Points[0]);

  pAInside:=SIMDTriangleContains(Triangle,Segment.Points[0]);
  pBInside:=SIMDTriangleContains(Triangle,Segment.Points[1]);

  if pAInside and pBInside then begin
   // both points inside triangle
   d1:=Vector3Dot(Triangle.Normal,Segment.Points[0])-dtri;
   d2:=Vector3Dot(Triangle.Normal,Segment.Points[1])-dtri;
   if abs(d2-d1)<EPSILON then begin
    // segment is parallel to triangle
    ClosestPointOnSegment:=Vector3Avg(Segment.Points[0],Segment.Points[1]);
    MinDist:=d1;
    Time:=0.5;
   end	else if abs(d1)<abs(d2) then begin
    ClosestPointOnSegment:=Segment.Points[0];
    MinDist:=d1;
    Time:=0.0;
   end else begin
    ClosestPointOnSegment:=Segment.Points[1];
    MinDist:=d2;
    Time:=1.0;
   end;
   ClosestPointOnTriangle:=Vector3Add(ClosestPointOnSegment,Vector3ScalarMul(Triangle.Normal,-MinDist));
   result:=true;
   exit;
  end else if pAInside then begin
   // one point is inside triangle
   ClosestPointOnSegment:=Segment.Points[0];
   Time:=0.0;
   MinDist:=Vector3Dot(Triangle.Normal,ClosestPointOnSegment)-dtri;
   ClosestPointOnTriangle:=Vector3Add(ClosestPointOnSegment,Vector3ScalarMul(Triangle.Normal,-MinDist));
   MinDist:=sqr(MinDist);
  end else if pBInside then begin
   // one point is inside triangle
   ClosestPointOnSegment:=Segment.Points[1];
   Time:=1.0;
   MinDist:=Vector3Dot(Triangle.Normal,ClosestPointOnSegment)-dtri;
   ClosestPointOnTriangle:=Vector3Add(ClosestPointOnSegment,Vector3ScalarMul(Triangle.Normal,-MinDist));
   MinDist:=sqr(MinDist);
  end;

  // test edge 1
  Edge.Points[0]:=Triangle.Points[0];
  Edge.Points[1]:=Triangle.Points[1];
  SIMDSegmentClosestPoints(Segment,Edge,sa,pa,sb,pb);
  Dist:=Vector3DistSquared(pa,pb);
  if Dist<MinDist then begin
   MinDist:=Dist;
   Time:=sa;
   ClosestPointOnSegment:=pa;
   ClosestPointOnTriangle:=pb;
  end;

  // test edge 2
  Edge.Points[0]:=Triangle.Points[1];
  Edge.Points[1]:=Triangle.Points[2];
  SIMDSegmentClosestPoints(Segment,Edge,sa,pa,sb,pb);
  Dist:=Vector3DistSquared(pa,pb);
  if Dist<MinDist then begin
   MinDist:=Dist;
   Time:=sa;
   ClosestPointOnSegment:=pa;
   ClosestPointOnTriangle:=pb;
  end;

  // test edge 3
  Edge.Points[0]:=Triangle.Points[2];
  Edge.Points[1]:=Triangle.Points[0];
  SIMDSegmentClosestPoints(Segment,Edge,sa,pa,sb,pb);
  Dist:=Vector3DistSquared(pa,pb);
  if Dist<MinDist then begin
// MinDist:=Dist;
   Time:=sa;
   ClosestPointOnSegment:=pa;
   ClosestPointOnTriangle:=pb;
  end;

 end;
  
end;

constructor TKraftHighResolutionTimer.Create(FrameRate:longint=60);
begin
 inherited Create;
 FrequencyShift:=0;
{$ifdef windows}
 if QueryPerformanceFrequency(Frequency) then begin
  while (Frequency and $ffffffffe0000000)<>0 do begin
   Frequency:=Frequency shr 1;
   inc(FrequencyShift);
  end;
 end else begin
  Frequency:=1000;
 end;
{$else}
{$ifdef linux}
  Frequency:=1000000000;
{$else}
{$ifdef unix}
  Frequency:=1000000;
{$else}
  Frequency:=1000;
{$endif}
{$endif}
{$endif}
 FrameInterval:=(Frequency+((abs(FrameRate)+1) shr 1)) div abs(FrameRate);
 MillisecondInterval:=(Frequency+500) div 1000;
 TwoMillisecondsInterval:=(Frequency+250) div 500;
 FourMillisecondsInterval:=(Frequency+125) div 250;
 QuarterSecondInterval:=(Frequency+2) div 4;
 HourInterval:=Frequency*3600;
end;

destructor TKraftHighResolutionTimer.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftHighResolutionTimer.SetFrameRate(FrameRate:longint);
begin
 FrameInterval:=(Frequency+((abs(FrameRate)+1) shr 1)) div abs(FrameRate);
end;

function TKraftHighResolutionTimer.GetTime:int64;
{$ifdef linux}
var NowTimeSpec:TimeSpec;
    ia,ib:int64;
{$else}
{$ifdef unix}
var tv:timeval;
    tz:timezone;
    ia,ib:int64;
{$endif}
{$endif}
begin
{$ifdef windows}
 if not QueryPerformanceCounter(result) then begin
  result:=timeGetTime;
 end;
{$else}
{$ifdef linux}
 clock_gettime(CLOCK_MONOTONIC,@NowTimeSpec);
 ia:=int64(NowTimeSpec.tv_sec)*int64(1000000000);
 ib:=NowTimeSpec.tv_nsec;
 result:=ia+ib;
{$else}
{$ifdef unix}
  tz.tz_minuteswest:=0;
  tz.tz_dsttime:=0;
  fpgettimeofday(@tv,@tz);
  ia:=int64(tv.tv_sec)*int64(1000000);
  ib:=tv.tv_usec;
  result:=ia+ib;
{$else}
 result:=SDL_GetTicks;
{$endif}
{$endif}
{$endif}
 result:=result shr FrequencyShift;
end;

function TKraftHighResolutionTimer.GetEventTime:int64;
begin
 result:=ToNanoseconds(GetTime);
end;

procedure TKraftHighResolutionTimer.Sleep(Delay:int64);
var EndTime,NowTime{$ifdef unix},SleepTime{$endif}:int64;
{$ifdef unix}
    req,rem:timespec;
{$endif}
begin
 if Delay>0 then begin
{$ifdef windows}
  NowTime:=GetTime;
  EndTime:=NowTime+Delay;
  while (NowTime+TwoMillisecondsInterval)<EndTime do begin
   Sleep(1);
   NowTime:=GetTime;
  end;
  while (NowTime+MillisecondInterval)<EndTime do begin
   Sleep(0);
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$else}
{$ifdef linux}
  NowTime:=GetTime;
  EndTime:=NowTime+Delay;
  while true do begin
   SleepTime:=abs(EndTime-NowTime);
   if SleepTime>=FourMillisecondsInterval then begin
    SleepTime:=(SleepTime+2) shr 2;
    if SleepTime>0 then begin
     req.tv_sec:=SleepTime div 1000000000;
     req.tv_nsec:=SleepTime mod 10000000000;
     fpNanoSleep(@req,@rem);
     NowTime:=GetTime;
     continue;
    end;
   end;
   break;
  end;
  while (NowTime+TwoMillisecondsInterval)<EndTime do begin
   ThreadSwitch;
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$else}
{$ifdef unix}
  NowTime:=GetTime;
  EndTime:=NowTime+Delay;
  while true do begin
   SleepTime:=abs(EndTime-NowTime);
   if SleepTime>=FourMillisecondsInterval then begin
    SleepTime:=(SleepTime+2) shr 2;
    if SleepTime>0 then begin
     req.tv_sec:=SleepTime div 1000000;
     req.tv_nsec:=(SleepTime mod 1000000)*1000;
     fpNanoSleep(@req,@rem);
     NowTime:=GetTime;
     continue;
    end;
   end;
   break;
  end;
  while (NowTime+TwoMillisecondsInterval)<EndTime do begin
   ThreadSwitch;
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$else}
  NowTime:=GetTime;
  EndTime:=NowTime+Delay;
  while (NowTime+4)<EndTime then begin
   SDL_Delay(1);
   NowTime:=GetTime;
  end;
  while (NowTime+2)<EndTime do begin
   SDL_Delay(0);
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$endif}
{$endif}
{$endif}
 end;
end;

function TKraftHighResolutionTimer.ToFixedPointSeconds(Time:int64):int64;
var a,b:TUInt128;
begin
 if Frequency<>0 then begin
  if ((Frequency or Time) and int64($ffffffff00000000))=0 then begin
   result:=int64(qword(qword(Time)*qword($100000000)) div qword(Frequency));
  end else begin
   UInt128Mul64(a,Time,qword($100000000));
   UInt128Div64(b,a,Frequency);
   result:=b.Lo;
  end;
 end else begin
  result:=0;
 end;
end;

function TKraftHighResolutionTimer.ToFixedPointFrames(Time:int64):int64;
var a,b:TUInt128;
begin
 if FrameInterval<>0 then begin
  if ((FrameInterval or Time) and int64($ffffffff00000000))=0 then begin
   result:=int64(qword(qword(Time)*qword($100000000)) div qword(FrameInterval));
  end else begin
   UInt128Mul64(a,Time,qword($100000000));
   UInt128Div64(b,a,FrameInterval);
   result:=b.Lo;
  end;
 end else begin
  result:=0;
 end;
end;

function TKraftHighResolutionTimer.ToFloatSeconds(Time:int64):double;
begin
 if Frequency<>0 then begin
  result:=Time/Frequency;
 end else begin
  result:=0;
 end;
end;

function TKraftHighResolutionTimer.FromFloatSeconds(Time:double):int64;
begin
 if Frequency<>0 then begin
  result:=trunc(Time*Frequency);
 end else begin
  result:=0;
 end;
end;

function TKraftHighResolutionTimer.ToMilliseconds(Time:int64):int64;
begin
 result:=Time;
 if Frequency<>1000 then begin
  result:=((Time*1000)+((Frequency+1) shr 1)) div Frequency;
 end;
end;

function TKraftHighResolutionTimer.FromMilliseconds(Time:int64):int64;
begin
 result:=Time;
 if Frequency<>1000 then begin
  result:=((Time*Frequency)+500) div 1000;
 end;
end;

function TKraftHighResolutionTimer.ToMicroseconds(Time:int64):int64;
begin
 result:=Time;
 if Frequency<>1000000 then begin
  result:=((Time*1000000)+((Frequency+1) shr 1)) div Frequency;
 end;
end;

function TKraftHighResolutionTimer.FromMicroseconds(Time:int64):int64;
begin
 result:=Time;
 if Frequency<>1000000 then begin
  result:=((Time*Frequency)+500000) div 1000000;
 end;
end;

function TKraftHighResolutionTimer.ToNanoseconds(Time:int64):int64;
begin
 result:=Time;
 if Frequency<>1000000000 then begin
  result:=((Time*1000000000)+((Frequency+1) shr 1)) div Frequency;
 end;
end;

function TKraftHighResolutionTimer.FromNanoseconds(Time:int64):int64;
begin
 result:=Time;
 if Frequency<>1000000000 then begin
  result:=((Time*Frequency)+500000000) div 1000000000;
 end;
end;

function CalculateArea(const v0,v1,v2:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Vector3LengthSquared(Vector3Cross(Vector3Sub(v1,v0),Vector3Sub(v2,v0)));
end;

function CalculateVolume(const v0,v1,v2,v3:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
var a,b,c:TKraftVector3;
begin
 a:=Vector3Sub(v0,v3);
 b:=Vector3Sub(v1,v3);
 c:=Vector3Sub(v2,v3);
 result:=(a.x*((b.z*c.y)-(b.y*c.z)))+(a.y*((b.x*c.z)-(b.z*c.x)))+(a.z*((b.y*c.x)-(b.x*c.y)));
end;

type TKraftShapeTriangle=class(TKraftShapeConvexHull)
      private
       ShapeConvexHull:TKraftConvexHull;
       procedure UpdateData;
      public
       constructor Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AVertex0,AVertex1,AVertex2:TKraftVector3); reintroduce;
       destructor Destroy; override;
       procedure UpdateShapeAABB; override;
       procedure CalculateMassData; override;
       function GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3; override;
       function GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3; override;
       function GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint; override;
       function GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3; override;
       function TestPoint(const p:TKraftVector3):boolean; override;
       function RayCast(var RayCastData:TKraftRaycastData):boolean; override;
{$ifdef DebugDraw}
       procedure Draw(const CameraMatrix:TKraftMatrix4x4); override;
{$endif}
     end;

function IsSameValue(const a,b:TKraftScalar):boolean;
const FuzzFactor=1000.0;
      SingleResolution={$ifdef UseDouble}1e-15{$else}1e-7{$endif}*FuzzFactor;
var EpsilonTolerance:double;
begin
 EpsilonTolerance:=abs(a);
 if EpsilonTolerance>abs(b) then begin
  EpsilonTolerance:=abs(b);
 end;
 EpsilonTolerance:=EpsilonTolerance*SingleResolution;
 if EpsilonTolerance<SingleResolution then begin
  EpsilonTolerance:=SingleResolution;
 end;
 if a>b then begin
  result:=(a-b)<=EpsilonTolerance;
 end else begin
  result:=(b-a)<=EpsilonTolerance;
 end;
end;

{$ifdef cpu386}
{$ifndef ver130}
function InterlockedCompareExchange64Ex(Target,NewValue,Comperand:pointer):boolean; assembler; register;
asm
 push ebx
 push edi
 push esi
 mov edi,eax
 mov esi,edx
 mov edx,dword ptr [ecx+4]
 mov eax,dword ptr [ecx+0]
 mov ecx,dword ptr [esi+4]
 mov ebx,dword ptr [esi+0]
 lock cmpxchg8b [edi]
 setz al
 pop esi
 pop edi
 pop ebx
end;

function InterlockedCompareExchange64(var Target:int64;NewValue:int64;Comperand:int64):int64; assembler; register;
asm
 push ebx
 push edi
 mov edi,eax
 mov edx,dword ptr [Comperand+4]
 mov eax,dword ptr [Comperand+0]
 mov ecx,dword ptr [NewValue+4]
 mov ebx,dword ptr [NewValue+0]
 lock cmpxchg8b [edi]
 pop edi
 pop ebx
end;
{$endif}
{$endif}

{$ifndef fpc}
{$ifdef cpu386}
function InterlockedDecrement(var Target:longint):longint; assembler; register;
asm
 mov edx,$ffffffff
 xchg eax,edx
 lock xadd dword ptr [edx],eax
 dec eax
end;

function InterlockedIncrement(var Target:longint):longint; assembler; register;
asm
 mov edx,1
 xchg eax,edx
 lock xadd dword ptr [edx],eax
 inc eax
end;

function InterlockedExchange(var Target:longint;Source:longint):longint; assembler; register;
asm
 lock xchg dword ptr [eax],edx
 mov eax,edx
end;

function InterlockedExchangeAdd(var Target:longint;Source:longint):longint; assembler; register;
asm
 xchg edx,eax
 lock xadd dword ptr [edx],eax
end;

function InterlockedCompareExchange(var Target:longint;NewValue,Comperand:longint):longint; assembler; register;
asm
 xchg ecx,eax
 lock cmpxchg dword ptr [ecx],edx
end;
{$else}
function InterlockedDecrement(var Target:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=Windows.InterlockedDecrement(Target);
end;

function InterlockedIncrement(var Target:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=Windows.InterlockedIncrement(Target);
end;

function InterlockedExchange(var Target:longint;Source:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=Windows.InterlockedExchange(Target,Source);
end;

function InterlockedExchangeAdd(var Target:longint;Source:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=Windows.InterlockedExchangeAdd(Target,Source);
end;

function InterlockedCompareExchange(var Target:longint;NewValue,Comperand:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=Windows.InterlockedCompareExchange(Target,NewValue,Comperand);
end;
{$endif}
{$else}
function InterlockedDecrement(var Target:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=System.InterlockedDecrement(Target);
end;

function InterlockedIncrement(var Target:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=System.InterlockedIncrement(Target);
end;

function InterlockedExchange(var Target:longint;Source:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=System.InterlockedExchange(Target,Source);
end;

function InterlockedExchangeAdd(var Target:longint;Source:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=System.InterlockedExchangeAdd(Target,Source);
end;

function InterlockedCompareExchange(var Target:longint;NewValue,Comperand:longint):longint; {$ifdef caninline}inline;{$endif}
begin
 result:=System.InterlockedCompareExchange(Target,NewValue,Comperand);
end;
{$endif}

function HashPointer(p:pointer):longword; {$ifdef caninline}inline;{$endif}
(*{$ifdef cpu64}
var r:qword;
begin
 r:=ptruint(p);
 r:=r xor (r shr 33);
 r:=r*qword($ff51afd7ed558ccd);
 r:=r xor (r shr 33);
 r:=r*qword($c4ceb9fe1a85ec53);
 result:=longword(ptruint(r xor (r shr 33)));
end;
{$else}
begin
 result:=ptruint(p);
 result:=result xor (result shr 16);
 result:=result*$85ebca6b;
 result:=result xor (result shr 13);
 result:=result*$c2b2ae35;
 result:=result xor (result shr 16);
end;
{$endif}(**)
{$ifdef cpu64}
var r:ptruint;
begin
 r:=ptruint(p);
 r:=(not r)+(r shl 18); // r:=((r shl 18)-r-)1;
 r:=r xor (r shr 31);
 r:=r*21; // r:=(r+(r shl 2))+(r shl 4);
 r:=r xor (r shr 11);
 r:=r+(r shl 6);
 result:=longword(ptruint(r xor (r shr 22)));
end;
{$else}
begin
 result:=ptruint(p);
 result:=(not result)+(result shl 15);
 result:=result xor (result shr 15);
 inc(result,result shl 2);
 result:=(result xor (result shr 4))*2057;
 result:=result xor (result shr 16);
end;
{$endif}

function HashTwoLongWords(a,b:longword):longword; {$ifdef caninline}inline;{$endif}
var r:qword;
begin
 r:=(qword(a) shl 32) or b;
 r:=(not r)+(r shl 18); // r:=((r shl 18)-r-)1;
 r:=r xor (r shr 31);
{$ifdef cpu64}
 r:=r*21;
{$else}
 r:=(r+(r shl 2))+(r shl 4);
{$endif}
 r:=r xor (r shr 11);
 r:=r+(r shl 6);
 result:=longword(ptruint(r xor (r shr 22)));
end;

function HashTwoPointers(a,b:pointer):longword; {$ifdef caninline}inline;{$endif}
begin
 result:=HashTwoLongWords(HashPointer(a),HashPointer(b));
end;

function HashTwoPointersAndOneLongWord(a,b:pointer;c:longword):longword; {$ifdef caninline}inline;{$endif}
begin
 result:=HashTwoLongWords(HashTwoLongWords(HashPointer(a),HashPointer(b)),c);
end;

function AABBStretch(const AABB:TKraftAABB;const Displacement,BoundsExpansion:TKraftVector3):TKraftAABB; {$ifdef caninline}inline;{$endif}
var d:TKraftVector3;
begin
 d:=Vector3Add(AABBExtensionVector,BoundsExpansion);
 result.Min:=Vector3Sub(AABB.Min,d);
 result.Max:=Vector3Add(AABB.Max,d);
 d:=Vector3ScalarMul(Displacement,AABB_MULTIPLIER);
 if d.x<0.0 then begin
  result.Min.x:=result.Min.x+d.x;
 end else if d.x>0.0 then begin
  result.Max.x:=result.Max.x+d.x;
 end;
 if d.y<0.0 then begin
  result.Min.y:=result.Min.y+d.y;
 end else if d.y>0.0 then begin
  result.Max.y:=result.Max.y+d.y;
 end;
 if d.z<0.0 then begin
  result.Min.z:=result.Min.z+d.z;
 end else if d.z>0.0 then begin
  result.Max.z:=result.Max.z+d.z;
 end;
end;

function CompareFloat(const a,b:pointer):longint;
begin
 if TKraftScalar(a^)<TKraftScalar(b^) then begin
  result:=1;
 end else if TKraftScalar(a^)>TKraftScalar(b^) then begin
  result:=-1;
 end else begin
  result:=0;
 end;
end;

function SweepTransform(const Sweep:TKraftSweep;const Beta:TKraftScalar):TKraftMatrix4x4; {$ifdef caninline}inline;{$endif}
begin
 result:=QuaternionToMatrix4x4(QuaternionSlerp(Sweep.q0,Sweep.q,Beta));
 PKraftVector3(pointer(@result[3,0]))^:=Vector3Sub(Vector3Lerp(Sweep.c0,Sweep.c,Beta),Vector3TermMatrixMulBasis(Sweep.LocalCenter,result));
end;

function SweepTermAdvance(const Sweep:TKraftSweep;const Alpha:TKraftScalar):TKraftSweep; {$ifdef caninline}inline;{$endif}
var Beta:TKraftScalar;
begin
 Assert(Sweep.Alpha0<1.0);
 Beta:=(Alpha-Sweep.Alpha0)/(1.0-Sweep.Alpha0);
 result.LocalCenter:=Sweep.LocalCenter;
 result.c0:=Vector3Lerp(Sweep.c0,Sweep.c,Beta);
 result.c:=Sweep.c;
 result.q0:=QuaternionSlerp(Sweep.q0,Sweep.q,Beta);
 result.q:=Sweep.q;
 result.Alpha0:=Alpha;
end;

procedure SweepAdvance(var Sweep:TKraftSweep;const Alpha:TKraftScalar);
var Beta:TKraftScalar;
begin
 Beta:=(Alpha-Sweep.Alpha0)/(1.0-Sweep.Alpha0);
 Sweep.c0:=Vector3Lerp(Sweep.c0,Sweep.c,Beta);
 Sweep.q0:=QuaternionSlerp(Sweep.q0,Sweep.q,Beta);
 Sweep.Alpha0:=Alpha;
end;

function SweepTermNormalize(const Sweep:TKraftSweep):TKraftSweep; {$ifdef caninline}inline;{$endif}
begin
 result.LocalCenter:=Sweep.LocalCenter;
 result.c0:=Sweep.c0;
 result.c:=Sweep.c;
 result.q0:=QuaternionTermNormalize(Sweep.q0);
 result.q:=QuaternionTermNormalize(Sweep.q);
 result.Alpha0:=Sweep.Alpha0;
end;

procedure SweepNormalize(var Sweep:TKraftSweep); {$ifdef caninline}inline;{$endif}
begin
 QuaternionNormalize(Sweep.q0);
 QuaternionNormalize(Sweep.q);
end;

procedure ClipFace(const InVertices,OutVertices:TKraftConvexHullVertexList;const Plane:TKraftPlane);
var ve,NumVerts:longint;
    ds,de:TKraftScalar;
    FirstVertex,EndVertex:PKraftVector3;
begin
 NumVerts:=InVertices.Count;
 if NumVerts>=2 then begin
  FirstVertex:=@InVertices.Vertices[InVertices.Count-1];
  EndVertex:=@InVertices.Vertices[0];
  ds:=PlaneVectorDistance(Plane,FirstVertex^);
  for ve:=0 to NumVerts-1 do begin
   EndVertex:=@InVertices.Vertices[ve];
   de:=PlaneVectorDistance(Plane,EndVertex^);
   if ds<0.0 then begin
    if de<0.0 then begin
     OutVertices.Add(EndVertex^);
    end else begin
     OutVertices.Add(Vector3Lerp(FirstVertex^,EndVertex^,ds/(ds-de)));
    end;
   end else if de<0.0 then begin
    OutVertices.Add(Vector3Lerp(FirstVertex^,EndVertex^,ds/(ds-de)));
    OutVertices.Add(EndVertex^);
   end;
   FirstVertex:=EndVertex;
   ds:=de;
  end;
 end;
end;

function GetSkewSymmetricMatrixPlus(const v:TKraftVector3):TKraftMatrix3x3; overload; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=0.0;
 result[0,1]:=-v.z;
 result[0,2]:=v.y;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=v.z;
 result[1,1]:=0.0;
 result[1,2]:=-v.x;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=-v.y;
 result[2,1]:=v.x;
 result[2,2]:=0.0;
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function GetSkewSymmetricMatrixMinus(const v:TKraftVector3):TKraftMatrix3x3; overload; {$ifdef caninline}inline;{$endif}
begin
 result[0,0]:=0.0;
 result[0,1]:=v.z;
 result[0,2]:=-v.y;
{$ifdef SIMD}
 result[0,3]:=0.0;
{$endif}
 result[1,0]:=-v.z;
 result[1,1]:=0.0;
 result[1,2]:=v.x;
{$ifdef SIMD}
 result[1,3]:=0.0;
{$endif}
 result[2,0]:=v.y;
 result[2,1]:=-v.x;
 result[2,2]:=0.0;
{$ifdef SIMD}
 result[2,3]:=0.0;
{$endif}
end;

function EvaluateEulerEquation(const w1,w0,T:TKraftVector3;const dt:TKraftScalar;const I:TKraftMatrix3x3):TKraftVector3; {$ifdef caninline}inline;{$endif}
var w1xI:TKraftVector3;
begin
 w1xI:=Vector3TermMatrixMul(w1,I);
 result:=Vector3Sub(Vector3Add(w1xI,Vector3ScalarMul(Vector3Cross(w1,w1xI),dt)),Vector3Add(Vector3ScalarMul(T,dt),Vector3TermMatrixMul(w0,I)));
end;

function EvaluateEulerEquationDerivation(const w1,w0:TKraftVector3;const dt:TKraftScalar;const I:TKraftMatrix3x3):TKraftMatrix3x3; {$ifdef caninline}inline;{$endif}
var w1x,Iw1x:TKraftMatrix3x3;
begin
 w1x:=GetSkewSymmetricMatrixMinus(w1);
 Iw1x:=GetSkewSymmetricMatrixMinus(Vector3TermMatrixMul(w1,I));
 result:=Matrix3x3TermAdd(I,Matrix3x3TermScalarMul(Matrix3x3TermSub(Matrix3x3TermMul(w1x,I),Iw1x),dt));
end;

constructor TKraftConvexHullVertexList.Create;
begin
 inherited Create;
 Vertices:=nil;
 Capacity:=0;
 Count:=0;
 Color.r:=1.0;
 Color.b:=1.0;
 Color.g:=1.0;
 Color.a:=1.0;
end;

destructor TKraftConvexHullVertexList.Destroy;
begin
 SetLength(Vertices,0);
end;

procedure TKraftConvexHullVertexList.Clear;
begin
 Count:=0;
end;

procedure TKraftConvexHullVertexList.Add(const v:TKraftVector3);
var i:longint;
begin
 i:=Count;
 inc(Count);
 if Count>Capacity then begin
  Capacity:=Count*2;
  SetLength(Vertices,Capacity);
 end;
 Vertices[i]:=v;
end;

procedure GetPlaneSpace(const n:TKraftVector3;var p,q:TKraftVector3); {$ifdef caninline}inline;{$endif}
var a,k:TKraftScalar;
begin
 if abs(n.z)>0.70710678 then begin
  a:=sqr(n.y)+sqr(n.z);
  k:=1.0/sqrt(a);
  p.x:=0.0;
  p.y:=-(n.z*k);
  p.z:=n.y*k;
  q.x:=a*k;
  q.y:=-(n.x*p.z);
  q.z:=n.x*p.y;
 end else begin
  a:=sqr(n.x)+sqr(n.y);
  k:=1.0/sqrt(a);
  p.x:=-(n.y*k);
  p.y:=n.x*k;
  p.z:=0.0;
  q.x:=-(n.z*p.y);
  q.y:=n.z*p.x;
  q.z:=a*k;
 end;
end;

procedure ComputeBasis(var a:TKraftVector3;out b,c:TKraftVector3); overload; {$ifdef caninline}inline;{$endif}
begin
 // Suppose vector a has all equal components and is a unit vector: a = (s, s, s)
 // Then 3*s*s = 1, s = sqrt(1/3) = 0.57735027. This means that at least one component of a
 // unit vector must be greater or equal to 0.57735027. Can use SIMD select operation.
 if abs(a.x)>=0.57735027 then begin
  b.x:=a.y;
  b.y:=-a.x;
  b.z:=0.0;
 end else begin
  b.x:=0.0;
  b.y:=a.z;
  b.z:=-a.y;
 end;
 Vector3NormalizeEx(a);
 Vector3NormalizeEx(b);
 c:=Vector3NormEx(Vector3Cross(a,b));
end;

procedure ComputeBasis(const Normal:TKraftVector3;out Matrix:TKraftMatrix3x3;const IndexA:longint=0;const IndexB:longint=1;const IndexC:longint=2); overload; {$ifdef caninline}inline;{$endif}
var a,b,c:TKraftVector3;
begin
 a:=Normal;
 ComputeBasis(a,b,c);
 Matrix[IndexA,0]:=a.x;
 Matrix[IndexA,1]:=a.y;
 Matrix[IndexA,2]:=a.z;
{$ifdef SIMD}
 Matrix[IndexA,3]:=0.0;
{$endif}
 Matrix[IndexB,0]:=b.x;
 Matrix[IndexB,1]:=b.y;
 Matrix[IndexB,2]:=b.z;
{$ifdef SIMD}
 Matrix[IndexB,3]:=0.0;
{$endif}
 Matrix[IndexC,0]:=c.x;
 Matrix[IndexC,1]:=c.y;
 Matrix[IndexC,2]:=c.z;
{$ifdef SIMD}
 Matrix[IndexC,3]:=0.0;
{$endif}
end;

function RayCastSphere(const RayOrigin,RayDirection,SpherePosition:TKraftVector3;const Radius,MaxTime:TKraftScalar;var HitTime:TKraftScalar):boolean; overload; {$ifdef caninline}inline;{$endif}
var Origin,Direction,m:TKraftVector3;
    b,c,d,t:TKraftScalar;
begin
 result:=false;
 Origin:=RayOrigin;
 Direction:=RayDirection;
 m:=Vector3Sub(Origin,SpherePosition);
 b:=Vector3Dot(m,Direction);
 c:=Vector3LengthSquared(m)-sqr(Radius);
 if (c<=0.0) or (b<=0.0) then begin
  d:=sqr(b)-c;
  if d>=EPSILON then begin
   t:=(-b)-sqrt(d);
   if (t>=0.0) and (t<=MaxTime) then begin
    HitTime:=t;
    result:=true;
   end;
  end;
 end;
end;

function RayCastSphere(const RayOrigin,RayDirection,SpherePosition:TKraftVector3;const Radius,MaxTime:TKraftScalar;var HitTime:TKraftScalar;var HitPosition,HitNormal:TKraftVector3):boolean; overload; {$ifdef caninline}inline;{$endif}
var Origin,Direction,m:TKraftVector3;
    b,c,d,t:TKraftScalar;
begin
 result:=false;
 Origin:=RayOrigin;
 Direction:=RayDirection;
 m:=Vector3Sub(Origin,SpherePosition);
 b:=Vector3Dot(m,Direction);
 c:=Vector3LengthSquared(m)-sqr(Radius);
 if (c<=0.0) or (b<=0.0) then begin
  d:=sqr(b)-c;
  if d>=EPSILON then begin
   t:=(-b)-sqrt(d);
   if (t>=0.0) and (t<=MaxTime) then begin
    HitTime:=t;
    HitPosition:=Vector3Add(Origin,Vector3ScalarMul(Direction,t));
    HitNormal:=Vector3NormEx(Vector3Sub(HitPosition,SpherePosition));
    result:=true;
   end;
  end;
 end;
end;

function CalculateAreaFromThreePoints(const p0,p1,p2:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Vector3LengthSquared(Vector3Cross(Vector3Sub(p1,p0),Vector3Sub(p2,p0)));
end;

function CalculateAreaFromFourPoints(const p0,p1,p2,p3:TKraftVector3):TKraftScalar; overload; {$ifdef caninline}inline;{$endif}
begin
 result:=Max(Max(Vector3LengthSquared(Vector3Cross(Vector3Sub(p0,p1),Vector3Sub(p3,p3))),
                 Vector3LengthSquared(Vector3Cross(Vector3Sub(p0,p2),Vector3Sub(p1,p3)))),
                 Vector3LengthSquared(Vector3Cross(Vector3Sub(p0,p3),Vector3Sub(p1,p2))));
end;

function BoxGetDistanceToPoint(Point:TKraftVector3;const Extents:TKraftVector3;const InverseTransformMatrix,TransformMatrix:TKraftMatrix4x4;var ClosestBoxPoint:TKraftVector3):TKraftScalar;
var Temp,Direction:TKraftVector3;
    Overlap:longint;
begin
 result:=0;
 ClosestBoxPoint:=Vector3TermMatrixMul(Point,InverseTransformMatrix);
 if ClosestBoxPoint.x<-Extents.x then begin
  result:=result+sqr(ClosestBoxPoint.x-(-Extents.x));
  ClosestBoxPoint.x:=-Extents.x;
  Overlap:=0;
 end else if ClosestBoxPoint.x>Extents.x then begin
  result:=result+sqr(ClosestBoxPoint.x-Extents.x);
  ClosestBoxPoint.x:=Extents.x;
  Overlap:=0;
 end else begin
  Overlap:=1;
 end;
 if ClosestBoxPoint.y<-Extents.y then begin
  result:=result+sqr(ClosestBoxPoint.y-(-Extents.y));
  ClosestBoxPoint.y:=-Extents.y;
 end else if ClosestBoxPoint.y>Extents.y then begin
  result:=result+sqr(ClosestBoxPoint.y-Extents.y);
  ClosestBoxPoint.y:=Extents.y;
 end else begin
  Overlap:=Overlap or 2;
 end;
 if ClosestBoxPoint.z<-Extents.z then begin
  result:=result+sqr(ClosestBoxPoint.z-(-Extents.z));
  ClosestBoxPoint.z:=-Extents.z;
 end else if ClosestBoxPoint.z>Extents.z then begin
  result:=result+sqr(ClosestBoxPoint.z-Extents.z);
  ClosestBoxPoint.z:=Extents.z;
 end else begin
  Overlap:=Overlap or 3;
 end;
 if Overlap<>7 then begin
  result:=sqrt(result);
 end else begin
  Temp:=ClosestBoxPoint;
  Direction.x:=ClosestBoxPoint.x/Extents.x;
  Direction.y:=ClosestBoxPoint.y/Extents.y;
  Direction.z:=ClosestBoxPoint.z/Extents.z;
  if (abs(Direction.x)>abs(Direction.y)) and (abs(Direction.x)>abs(Direction.z)) then begin
   if Direction.x<0.0 then begin
    ClosestBoxPoint.x:=-Extents.x;
   end else begin
    ClosestBoxPoint.x:=Extents.x;
   end;
  end else if (abs(Direction.y)>abs(Direction.x)) and (abs(Direction.y)>abs(Direction.z)) then begin
   if Direction.y<0.0 then begin
    ClosestBoxPoint.y:=-Extents.y;
   end else begin
    ClosestBoxPoint.y:=Extents.y;
   end;
  end else begin
   if Direction.z<0.0 then begin
    ClosestBoxPoint.z:=-Extents.z;
   end else begin
    ClosestBoxPoint.z:=Extents.z;
   end;
  end;
  result:=-Vector3Dist(ClosestBoxPoint,Temp);
 end;
 ClosestBoxPoint:=Vector3TermMatrixMul(ClosestBoxPoint,TransformMatrix);
end;

type TSortCompareFunction=function(const a,b:pointer):longint;

function IntLog2(x:longword):longword; {$ifdef cpu386}assembler; register;
asm
 test eax,eax
 jz @Done
 bsr eax,eax
 @Done:
end;
{$else}
begin
 x:=x or (x shr 1);
 x:=x or (x shr 2);
 x:=x or (x shr 4);
 x:=x or (x shr 8);
 x:=x or (x shr 16);
 x:=x shr 1;
 x:=x-((x shr 1) and $55555555);
 x:=((x shr 2) and $33333333)+(x and $33333333);
 x:=((x shr 4)+x) and $0f0f0f0f;
 x:=x+(x shr 8);
 x:=x+(x shr 16);
 result:=x and $3f;
end;
{$endif}

procedure DirectIntroSort(Items:pointer;Left,Right,ElementSize:longint;CompareFunc:TSortCompareFunction);
type PByteArray=^TByteArray;
     TByteArray=array[0..$3fffffff] of byte;
     PStackItem=^TStackItem;
     TStackItem=record
      Left,Right,Depth:longint;
     end;
var Depth,i,j,Middle,Size,Parent,Child:longint;
    Pivot,Temp:pointer;
    StackItem:PStackItem;
    Stack:array[0..31] of TStackItem;
begin
 if Left<Right then begin
  GetMem(Temp,ElementSize);
  GetMem(Pivot,ElementSize);
  try
   StackItem:=@Stack[0];
   StackItem^.Left:=Left;
   StackItem^.Right:=Right;
   StackItem^.Depth:=IntLog2((Right-Left)+1) shl 1;
   inc(StackItem);
   while ptruint(pointer(StackItem))>ptruint(pointer(@Stack[0])) do begin
    dec(StackItem);
    Left:=StackItem^.Left;
    Right:=StackItem^.Right;
    Depth:=StackItem^.Depth;
    if (Right-Left)<16 then begin
     // Insertion sort
     for i:=Left+1 to Right do begin
      j:=i-1;
      if (j>=Left) and (CompareFunc(pointer(@PByteArray(Items)^[j*ElementSize]),pointer(@PByteArray(Items)^[i*ElementSize]))>0) then begin
       Move(PByteArray(Items)^[i*ElementSize],Temp^,ElementSize);
       repeat
        Move(PByteArray(Items)^[j*ElementSize],PByteArray(Items)^[(j+1)*ElementSize],ElementSize);
        dec(j);
       until not ((j>=Left) and (CompareFunc(pointer(@PByteArray(Items)^[j*ElementSize]),Temp)>0));
       Move(Temp^,PByteArray(Items)^[(j+1)*ElementSize],ElementSize);
      end;
     end;
    end else begin
     if (Depth=0) or (ptruint(pointer(StackItem))>=ptruint(pointer(@Stack[high(Stack)-1]))) then begin
      // Heap sort
      Size:=(Right-Left)+1;
      i:=Size div 2;
      repeat
       if i>Left then begin
        dec(i);
        Move(PByteArray(Items)^[(Left+i)*ElementSize],Temp^,ElementSize);
       end else begin
        if Size=0 then begin
         break;
        end else begin
         dec(Size);
         Move(PByteArray(Items)^[(Left+Size)*ElementSize],Temp^,ElementSize);
         Move(PByteArray(Items)^[Left*ElementSize],PByteArray(Items)^[(Left+Size)*ElementSize],ElementSize);
        end;
       end;
       Parent:=i;
       Child:=(i*2)+1;
       while Child<Size do begin
        if ((Child+1)<Size) and (CompareFunc(pointer(@PByteArray(Items)^[((Left+Child)+1)*ElementSize]),pointer(@PByteArray(Items)^[(Left+Child)*ElementSize]))>0) then begin
         inc(Child);
        end;
        if CompareFunc(pointer(@PByteArray(Items)^[(Left+Child)*ElementSize]),Temp)>0 then begin
         Move(PByteArray(Items)^[(Left+Child)*ElementSize],PByteArray(Items)^[(Left+Parent)*ElementSize],ElementSize);
         Parent:=Child;
         Child:=(Parent*2)+1;
        end else begin
         break;
        end;
       end;
       Move(Temp^,PByteArray(Items)^[(Left+Parent)*ElementSize],ElementSize);
      until false;
     end else begin
      // Quick sort width median-of-three optimization
      Middle:=Left+((Right-Left) shr 1);
      if (Right-Left)>3 then begin
       if CompareFunc(pointer(@PByteArray(Items)^[Left*ElementSize]),pointer(@PByteArray(Items)^[Middle*ElementSize]))>0 then begin
        Move(PByteArray(Items)^[Left*ElementSize],Temp^,ElementSize);
        Move(PByteArray(Items)^[Middle*ElementSize],PByteArray(Items)^[Left*ElementSize],ElementSize);
        Move(Temp^,PByteArray(Items)^[Middle*ElementSize],ElementSize);
       end;
       if CompareFunc(pointer(@PByteArray(Items)^[Left*ElementSize]),pointer(@PByteArray(Items)^[Right*ElementSize]))>0 then begin
        Move(PByteArray(Items)^[Left*ElementSize],Temp^,ElementSize);
        Move(PByteArray(Items)^[Right*ElementSize],PByteArray(Items)^[Left*ElementSize],ElementSize);
        Move(Temp^,PByteArray(Items)^[Right*ElementSize],ElementSize);
       end;
       if CompareFunc(pointer(@PByteArray(Items)^[Middle*ElementSize]),pointer(@PByteArray(Items)^[Right*ElementSize]))>0 then begin
        Move(PByteArray(Items)^[Middle*ElementSize],Temp^,ElementSize);
        Move(PByteArray(Items)^[Right*ElementSize],PByteArray(Items)^[Middle*ElementSize],ElementSize);
        Move(Temp^,PByteArray(Items)^[Right*ElementSize],ElementSize);
       end;
      end;
      Move(PByteArray(Items)^[Middle*ElementSize],Pivot^,ElementSize);
      i:=Left;
      j:=Right;
      repeat
       while (i<Right) and (CompareFunc(pointer(@PByteArray(Items)^[i*ElementSize]),Pivot)<0) do begin
        inc(i);
       end;
       while (j>=i) and (CompareFunc(pointer(@PByteArray(Items)^[j*ElementSize]),Pivot)>0) do begin
        dec(j);
       end;
       if i>j then begin
        break;
       end else begin
        if i<>j then begin
         Move(PByteArray(Items)^[i*ElementSize],Temp^,ElementSize);
         Move(PByteArray(Items)^[j*ElementSize],PByteArray(Items)^[i*ElementSize],ElementSize);
         Move(Temp^,PByteArray(Items)^[j*ElementSize],ElementSize);
        end;
        inc(i);
        dec(j);
       end;
      until false;
      if i<Right then begin
       StackItem^.Left:=i;
       StackItem^.Right:=Right;
       StackItem^.Depth:=Depth-1;
       inc(StackItem);
      end;
      if Left<j then begin
       StackItem^.Left:=Left;
       StackItem^.Right:=j;
       StackItem^.Depth:=Depth-1;
       inc(StackItem);
      end;
     end;
    end;
   end;
  finally
   FreeMem(Pivot);
   FreeMem(Temp);
  end;
 end;
end;

procedure IndirectIntroSort(Items:pointer;Left,Right:longint;CompareFunc:TSortCompareFunction);
type PPointers=^TPointers;
     TPointers=array[0..$ffff] of pointer;
     PStackItem=^TStackItem;
     TStackItem=record
      Left,Right,Depth:longint;
     end;
var Depth,i,j,Middle,Size,Parent,Child:longint;
    Pivot,Temp:pointer;
    StackItem:PStackItem;
    Stack:array[0..31] of TStackItem;
begin
 if Left<Right then begin
  StackItem:=@Stack[0];
  StackItem^.Left:=Left;
  StackItem^.Right:=Right;
  StackItem^.Depth:=IntLog2((Right-Left)+1) shl 1;
  inc(StackItem);
  while ptruint(pointer(StackItem))>ptruint(pointer(@Stack[0])) do begin
   dec(StackItem);
   Left:=StackItem^.Left;
   Right:=StackItem^.Right;
   Depth:=StackItem^.Depth;
   if (Right-Left)<16 then begin
    // Insertion sort
    for i:=Left+1 to Right do begin
     Temp:=PPointers(Items)^[i];
     j:=i-1;
     if (j>=Left) and (CompareFunc(PPointers(Items)^[j],Temp)>0) then begin
      repeat
       PPointers(Items)^[j+1]:=PPointers(Items)^[j];
       dec(j);
      until not ((j>=Left) and (CompareFunc(PPointers(Items)^[j],Temp)>0));
      PPointers(Items)^[j+1]:=Temp;
     end;
    end;
   end else begin
    if (Depth=0) or (ptruint(pointer(StackItem))>=ptruint(pointer(@Stack[high(Stack)-1]))) then begin
     // Heap sort
     Size:=(Right-Left)+1;
     i:=Size div 2;
     Temp:=nil;
     repeat
      if i>Left then begin
       dec(i);
       Temp:=PPointers(Items)^[Left+i];
      end else begin
       if Size=0 then begin
        break;
       end else begin
        dec(Size);
        Temp:=PPointers(Items)^[Left+Size];
        PPointers(Items)^[Left+Size]:=PPointers(Items)^[Left];
       end;
      end;
      Parent:=i;
      Child:=(i*2)+1;
      while Child<Size do begin
       if ((Child+1)<Size) and (CompareFunc(PPointers(Items)^[Left+Child+1],PPointers(Items)^[Left+Child])>0) then begin
        inc(Child);
       end;
       if CompareFunc(PPointers(Items)^[Left+Child],Temp)>0 then begin
        PPointers(Items)^[Left+Parent]:=PPointers(Items)^[Left+Child];
        Parent:=Child;
        Child:=(Parent*2)+1;
       end else begin
        break;
       end;
      end;
      PPointers(Items)^[Left+Parent]:=Temp;
     until false;
    end else begin
     // Quick sort width median-of-three optimization
     Middle:=Left+((Right-Left) shr 1);
     if (Right-Left)>3 then begin
      if CompareFunc(PPointers(Items)^[Left],PPointers(Items)^[Middle])>0 then begin
       Temp:=PPointers(Items)^[Left];
       PPointers(Items)^[Left]:=PPointers(Items)^[Middle];
       PPointers(Items)^[Middle]:=Temp;
      end;
      if CompareFunc(PPointers(Items)^[Left],PPointers(Items)^[Right])>0 then begin
       Temp:=PPointers(Items)^[Left];
       PPointers(Items)^[Left]:=PPointers(Items)^[Right];
       PPointers(Items)^[Right]:=Temp;
      end;
      if CompareFunc(PPointers(Items)^[Middle],PPointers(Items)^[Right])>0 then begin
       Temp:=PPointers(Items)^[Middle];
       PPointers(Items)^[Middle]:=PPointers(Items)^[Right];
       PPointers(Items)^[Right]:=Temp;
      end;
     end;
     Pivot:=PPointers(Items)^[Middle];
     i:=Left;
     j:=Right;
     repeat
      while (i<Right) and (CompareFunc(PPointers(Items)^[i],Pivot)<0) do begin
       inc(i);
      end;
      while (j>=i) and (CompareFunc(PPointers(Items)^[j],Pivot)>0) do begin
       dec(j);
      end;
      if i>j then begin
       break;
      end else begin
       if i<>j then begin
        Temp:=PPointers(Items)^[i];
        PPointers(Items)^[i]:=PPointers(Items)^[j];
        PPointers(Items)^[j]:=Temp;
       end;
       inc(i);
       dec(j);
      end;
     until false;
     if i<Right then begin
      StackItem^.Left:=i;
      StackItem^.Right:=Right;
      StackItem^.Depth:=Depth-1;
      inc(StackItem);
     end;
     if Left<j then begin
      StackItem^.Left:=Left;
      StackItem^.Right:=j;
      StackItem^.Depth:=Depth-1;
      inc(StackItem);
     end;
    end;
   end;
  end;
 end;
end;

function SolveQuadraticRoots(const a,b,c:TKraftScalar;out t1,t2:TKraftScalar):boolean; {$ifdef caninline}inline;{$endif}
var d,InverseDenominator:TKraftScalar;
begin
 result:=false;
 d:=sqr(b)-(4.0*(a*c));
 if d>=0.0 then begin
  InverseDenominator:=1.0/(2.0*a);
  if abs(d)<EPSILON then begin
   t1:=(-b)*InverseDenominator;
   t2:=t1;
  end else begin
   d:=sqrt(d);
   t1:=((-b)-d)*InverseDenominator;
   t2:=((-b)+d)*InverseDenominator;
  end;
  result:=true;
 end;
end;

function SweepSphereSphere(const pa0,pa1:TKraftVector3;const ra:TKraftScalar;const pb0,pb1:TKraftVector3;const rb:TKraftScalar;out t0,t1:TKraftScalar):boolean; overload; {$ifdef caninline}inline;{$endif}
var va,vb,ab,vab:TKraftVector3;
    rab,a,b,c:TKraftScalar;
begin
 va:=Vector3Sub(pa1,pa0);
 vb:=Vector3Sub(pb1,pb0);
 ab:=Vector3Sub(pb0,pa0);
 vab:=Vector3Sub(vb,va);
 rab:=ra+rb;
 a:=Vector3LengthSquared(vab);
 c:=Vector3LengthSquared(ab)-sqr(rab);
 if (abs(a)<EPSILON) or (c<=0.0) then begin
  t0:=0.0;
  t1:=0.0;
  result:=true;
 end else begin
  b:=2.0*Vector3Dot(vab,ab);
  if SolveQuadraticRoots(a,b,c,t0,t1) then begin
   if t1>t0 then begin
    a:=t0;
    t0:=t1;
    t1:=a;
   end;
   result:=(t1>=0.0) and (t0<=1.0);
  end else begin
   result:=false;
  end;
 end;
end;

function SweepSphereSphere(const pa0,pa1:TKraftVector3;const ra:TKraftScalar;const pb0,pb1:TKraftVector3;const rb:TKraftScalar;out Time,Distance:TKraftScalar;out Normal:TKraftVector3):boolean; overload; {$ifdef caninline}inline;{$endif}
var t0,t1:TKraftScalar;
begin
 result:=SweepSphereSphere(pa0,pa1,ra,pb0,pb1,rb,t0,t1);
 if result then begin
  Time:=t0;
  Normal:=Vector3Sub(Vector3Lerp(pb0,pb1,t0),Vector3Lerp(pa0,pa1,t0));
  Distance:=Vector3LengthNormalize(Normal);
  if Distance<EPSILON then begin
   Normal:=Vector3Sub(pb0,pb1);
   if Vector3LengthNormalize(Normal)<EPSILON then begin
    Normal:=Vector3Sub(pa1,pa0);
   end;
  end;
 end;
end;

function MPRIntersection(const ShapeA,ShapeB:TKraftShape;const TransformA,TransformB:TKraftMatrix4x4):boolean;
var Phase1Iteration,Phase2Iterations:longint;
    v0,v1,v2,v3,v4,t,n:TKraftVector3;
begin
 result:=false;

 v0:=Vector3Sub(ShapeB.GetCenter(TransformB),ShapeA.GetCenter(TransformA));

 if Vector3LengthSquared(v0)<1e-5 then begin
  v0.x:=1e-5;
 end;

 n:=Vector3Neg(v0);
 v1:=Vector3Sub(Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB),
                    Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(v0,TransformA)),TransformA));
 if Vector3Dot(v1,n)<=0.0 then begin
  exit;
 end;

 n:=Vector3Cross(v1,v0);
 if Vector3LengthSquared(n)<EPSILON then begin
  result:=true;
  exit;
 end;

 v2:=Vector3Sub(Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB),
                    Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(Vector3Neg(n),TransformA)),TransformA));
 if Vector3Dot(v2,n)<=0.0 then begin
  exit;
 end;

 n:=Vector3Cross(Vector3Sub(v1,v0),Vector3Sub(v2,v0));
 if Vector3Dot(n,v0)>0.0 then begin
  t:=v1;
  v1:=v2;
  v2:=t;
  n:=Vector3Neg(n);
 end;

 for Phase1Iteration:=1 to MPRMaximumIterations do begin

  v3:=Vector3Sub(Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB),
                     Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(Vector3Neg(n),TransformA)),TransformA));
  if Vector3Dot(v3,n)<=0.0 then begin
   exit;
  end;

{ t:=Vector3Cross(v3,v0);

  if Vector3Dot(t,v1)<0.0 then begin}
  if Vector3Dot(v0,Vector3Cross(v3,v1))>0.0 then begin
   v2:=v3;
   n:=Vector3Cross(Vector3Sub(v1,v0),Vector3Sub(v3,v0));
   continue;
  end;

//if Vector3Dot(t,v2)>0.0 then begin
  if Vector3Dot(v0,Vector3Cross(v2,v3))>0.0 then begin
   v1:=v3;
   n:=Vector3Cross(Vector3Sub(v3,v0),Vector3Sub(v2,v0));
   continue;
  end;

  Phase2Iterations:=0;

  repeat
   inc(Phase2Iterations);
   n:=Vector3Cross(Vector3Sub(v2,v1),Vector3Sub(v3,v1));
   if Vector3LengthSquared(n)<EPSILON then begin
    result:=true;
    exit;
   end;
   Vector3Normalize(n);
   if (Vector3Dot(v1,n)>=0.0) and not result then begin
    result:=true;
   end;
   v4:=Vector3Sub(Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB),
                      Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(Vector3Neg(n),TransformA)),TransformA));
   if (Vector3Dot(Vector3Sub(v4,v3),n)<=MPRTolerance) or
      (Vector3Dot(v4,n)<=0.0) or
      (Phase2Iterations>MPRMaximumIterations) then begin
    exit;
   end;
   t:=Vector3Cross(v4,v0);
   if Vector3Dot(t,v1)>0.0 then begin
    if Vector3Dot(t,v2)>0.0 then begin
     v1:=v4;
    end else begin
     v3:=v4;
    end;
   end else begin
    if Vector3Dot(t,v3)>0.0 then begin
     v2:=v4;
    end else begin
     v1:=v4;
    end;
   end;
  until false;
  
 end;

end;

function MPRPenetration(const ShapeA,ShapeB:TKraftShape;const TransformA,TransformB:TKraftMatrix4x4;out PositionA,PositionB,Normal:TKraftVector3;out PenetrationDepth:TKraftScalar):boolean;
var Phase1Iteration,Phase2Iterations:longint;
    b0,b1,b2,b3,Sum,Inv:TKraftScalar;
    v0,v0a,v0b,v1,v1a,v1b,v2,v2a,v2b,v3,v3a,v3b,v4,v4a,v4b,t,n:TKraftVector3;
begin
 result:=false;

 PositionA:=Vector3Origin;
 PositionB:=Vector3Origin;
 PenetrationDepth:=0.0;

 v0a:=ShapeA.GetCenter(TransformA);
 v0b:=ShapeB.GetCenter(TransformB);
 v0:=Vector3Sub(v0b,v0a);

 if Vector3LengthSquared(v0)<1e-5 then begin
  v0.x:=1e-5;
 end;

 n:=Vector3Neg(v0);
 v1a:=Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(v0,TransformA)),TransformA);
 v1b:=Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB);
 v1:=Vector3Sub(v1b,v1a);
 if Vector3Dot(v1,n)<=0.0 then begin
  Normal:=n;
  exit;
 end;

 n:=Vector3Cross(v1,v0);
 if Vector3LengthSquared(n)<EPSILON then begin
  PositionA:=v1a;
  PositionB:=v1b;
  Normal:=Vector3Norm(Vector3Sub(v1,v0));
  PenetrationDepth:=Vector3Dot(Vector3Sub(v1b,v1a),Normal);
  result:=true;
  exit;
 end;

 v2a:=Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(Vector3Neg(n),TransformA)),TransformA);
 v2b:=Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB);
 v2:=Vector3Sub(v2b,v2a);
 if Vector3Dot(v2,n)<=0.0 then begin
  Normal:=n;
  exit;
 end;

 n:=Vector3Cross(Vector3Sub(v1,v0),Vector3Sub(v2,v0));
 if Vector3Dot(n,v0)>0.0 then begin
  t:=v1;
  v1:=v2;
  v2:=t;
  t:=v1a;
  v1a:=v2a;
  v2a:=t;
  t:=v1b;
  v1b:=v2b;
  v2b:=t;
  n:=Vector3Neg(n);
 end;

 for Phase1Iteration:=1 to MPRMaximumIterations do begin

  v3a:=Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(Vector3Neg(n),TransformA)),TransformA);
  v3b:=Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB);
  v3:=Vector3Sub(v3b,v3a);
  if Vector3Dot(v3,n)<=0.0 then begin
   Normal:=n;
   exit;
  end;

{ t:=Vector3Cross(v3,v0);

  if Vector3Dot(t,v1)<0.0 then begin}
  if Vector3Dot(v0,Vector3Cross(v3,v1))>0.0 then begin
   v2:=v3;
   v2a:=v3a;
   v2b:=v3b;
   n:=Vector3Cross(Vector3Sub(v1,v0),Vector3Sub(v3,v0));
   continue;
  end;

//if Vector3Dot(t,v2)>0.0 then begin
  if Vector3Dot(v0,Vector3Cross(v2,v3))>0.0 then begin
   v1:=v3;
   v1a:=v3a;
   v1b:=v3b;
   n:=Vector3Cross(Vector3Sub(v3,v0),Vector3Sub(v2,v0));
   continue;
  end;

  Phase2Iterations:=0;

  repeat

   inc(Phase2Iterations);

   n:=Vector3Cross(Vector3Sub(v2,v1),Vector3Sub(v3,v1));

   if Vector3LengthSquared(n)<EPSILON then begin
    PositionA:=v1a;
    PositionB:=v1b;
    Normal:=Vector3Norm(Vector3Sub(v1,v0));
    PenetrationDepth:=Vector3Dot(Vector3Sub(v1b,v1a),Normal);
    result:=true;
    exit;
   end;

   Vector3Normalize(n);

   if (Vector3Dot(v1,n)>=0.0) and not result then begin
    result:=true;
   end;

   v4a:=Vector3TermMatrixMul(ShapeA.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(Vector3Neg(n),TransformA)),TransformA);
   v4b:=Vector3TermMatrixMul(ShapeB.GetLocalFullSupport(Vector3TermMatrixMulTransposedBasis(n,TransformB)),TransformB);
   v4:=Vector3Sub(v4b,v4a);

   PenetrationDepth:=Vector3Dot(v4,n);

   if (Vector3Dot(Vector3Sub(v4,v3),n)<=MPRTolerance) or
      (PenetrationDepth<=0.0) or
      (Phase2Iterations>MPRMaximumIterations) then begin

    if result then begin

     Normal:=n;

     b0:=Vector3Dot(Vector3Cross(v1,v2),v3);
     b1:=Vector3Dot(Vector3Cross(v3,v2),v0);
     b2:=Vector3Dot(Vector3Cross(v0,v1),v3);
     b3:=Vector3Dot(Vector3Cross(v2,v1),v0);

     Sum:=b0+b1+b2+b3;

     if Sum<=0.0 then begin

      b0:=0.0;
      b1:=Vector3Dot(Vector3Cross(v2,v3),n);
      b2:=Vector3Dot(Vector3Cross(v3,v1),n);
      b3:=Vector3Dot(Vector3Cross(v1,v2),n);

      Sum:=b1+b2+b3;

     end;

     Inv:=1.0/Sum;

     PositionA.x:=((v0a.x*b0)+(v1a.x*b1)+(v2a.x*b2)+(v3a.x*b3))*Inv;
     PositionA.y:=((v0a.y*b0)+(v1a.y*b1)+(v2a.y*b2)+(v3a.y*b3))*Inv;
     PositionA.z:=((v0a.z*b0)+(v1a.z*b1)+(v2a.z*b2)+(v3a.z*b3))*Inv;

     PositionB.x:=((v0b.x*b0)+(v1b.x*b1)+(v2b.x*b2)+(v3b.x*b3))*Inv;
     PositionB.y:=((v0b.y*b0)+(v1b.y*b1)+(v2b.y*b2)+(v3b.y*b3))*Inv;
     PositionB.z:=((v0b.z*b0)+(v1b.z*b1)+(v2b.z*b2)+(v3b.z*b3))*Inv;

    end;

    exit;

   end;

   t:=Vector3Cross(v4,v0);

   if Vector3Dot(t,v1)>0.0 then begin

    if Vector3Dot(t,v2)>0.0 then begin

     v1:=v4;
     v1a:=v4a;
     v1b:=v4b;

    end else begin

     v3:=v4;
     v3a:=v4a;
     v3b:=v4b;

    end;

   end else begin

    if Vector3Dot(t,v3)>0.0 then begin

     v2:=v4;
     v2a:=v4a;
     v2b:=v4b;

    end else begin

     v1:=v4;
     v1a:=v4a;
     v1b:=v4b;

    end;

   end;

  until false;

 end;

end;

function TKraftGJK.Run:boolean;
var CountSaved,Index,iA,iB:longint;
    Initialized,Duplicate:boolean;
    SimplexVertex:PKraftGJKSimplexVertex;
    CachedSimplexVertex:PKraftGJKCachedSimplexVertex;
    Metrics,SquaredDistances:array[0..1] of TKraftScalar;
    Saved:array[0..3,0..1] of longint;
    Direction,a,b,c,d,ba,ab,cb,bc,ac,ca,db,bd,cd,dc,da,ad,baxca,daxba,bcxdc,caxda:TKraftVector3;
    uAB,vAB,uBC,vBC,uCA,vCA,uBD,vBD,uDC,vDC,uAD,vAD,uADB,vADB,wADB,uACD,vACD,wACD,uCBD,vCBD,wCBD,
    uABC,vABC,wABC,uABCD,vABCD,wABCD,xABCD,Denominator:TKraftScalar;
    TempVertex:PKraftGJKSimplexVertex;
begin

 Failed:=false;

 Initialized:=false;

 // Initialize simplex vertex permutation order
 Simplex.Vertices[0]:=@Simplex.VerticesData[0];
 Simplex.Vertices[1]:=@Simplex.VerticesData[1];
 Simplex.Vertices[2]:=@Simplex.VerticesData[2];
 Simplex.Vertices[3]:=@Simplex.VerticesData[3];

 // Try refill from cache
 if assigned(CachedSimplex) then begin
  Simplex.Count:=CachedSimplex^.Count;
  if Simplex.Count>0 then begin
   for Index:=0 to Simplex.Count-1 do begin
    CachedSimplexVertex:=@CachedSimplex^.Vertices[Index];
    SimplexVertex:=Simplex.Vertices[Index];
    SimplexVertex^.iA:=CachedSimplexVertex^.iA;
    SimplexVertex^.iB:=CachedSimplexVertex^.iB;
    SimplexVertex^.sA:=Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(SimplexVertex^.iA),Transforms[0]^);
    SimplexVertex^.sB:=Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(SimplexVertex^.iB),Transforms[1]^);
    SimplexVertex^.w:=Vector3Sub(SimplexVertex^.sB,SimplexVertex^.sA);
    SimplexVertex^.a:=CachedSimplexVertex^.a;
   end;
   Metrics[0]:=CachedSimplex^.Metric;
   case Simplex.Count of
    1:begin
     Metrics[1]:=0.0;
    end;
    2:begin
     Metrics[1]:=Vector3Dist(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w);
    end;
    3:begin
     Metrics[1]:=CalculateArea(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w,Simplex.Vertices[2]^.w);
    end;
    4:begin
     Metrics[1]:=CalculateVolume(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w,Simplex.Vertices[2]^.w,Simplex.Vertices[3]^.w);
    end;
    else begin
     Assert(false);
     Metrics[1]:=0.0;
    end;
   end;
   if not ((Metrics[1]<(Metrics[0]*0.5)) or ((Metrics[0]*2.0)<Metrics[1]) or (Metrics[1]<EPSILON)) then begin
    Initialized:=true;
   end;
  end;
 end;

 // Initialize simplex if the cache was empty or its content was invalid
 if not Initialized then begin
  SimplexVertex:=Simplex.Vertices[0];
  SimplexVertex^.iA:=0;
  SimplexVertex^.iB:=0;
  SimplexVertex^.sA:=Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(0),Transforms[0]^);
  SimplexVertex^.sB:=Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(0),Transforms[1]^);
  SimplexVertex^.w:=Vector3Sub(SimplexVertex^.sB,SimplexVertex^.sA);
  SimplexVertex^.a:=1.0;
  Simplex.Count:=1;
 end;

 SquaredDistances[0]:=MAX_SCALAR;
 SquaredDistances[1]:=MAX_SCALAR;

 Iterations:=0;

 // The main loop
 repeat

  // Remember old simplex vertex indices
  CountSaved:=Simplex.Count;
  for Index:=0 to CountSaved-1 do begin
   Saved[Index,0]:=Simplex.Vertices[Index]^.iA;
   Saved[Index,1]:=Simplex.Vertices[Index]^.iB;
  end;

  // Reduce simplex
  case Simplex.Count of
   1:begin
    // Point
   end;
   2:begin
    // Line
    a:=Simplex.Vertices[0]^.w;
    b:=Simplex.Vertices[1]^.w;
    vAB:=Vector3Dot(a,Vector3Sub(a,b));
    if vAB<=0.0 then begin
     // Region A
     Simplex.Vertices[0].a:=1.0;
     Simplex.Divisor:=1.0;
     Simplex.Count:=1;
    end else begin
     uAB:=Vector3Dot(b,Vector3Sub(b,a));
     if uAB<=0.0 then begin
      // Region B
      TempVertex:=Simplex.Vertices[0];
      Simplex.Vertices[0]:=Simplex.Vertices[1];
      Simplex.Vertices[1]:=TempVertex;
      Simplex.Vertices[0]^.a:=1.0;
      Simplex.Divisor:=1.0;
      Simplex.Count:=1;
     end else begin
      if abs(uAB+vAB)<EPSILON then begin
       // Terminate on affinely dependent points in the set (if uAB+vAB is (nearly) zero, we can never use point B)
       Simplex.Vertices[0]^.a:=1.0;
       Simplex.Divisor:=1.0;
       Simplex.Count:=1;
      end else begin
       // Region AB
       Simplex.Vertices[0]^.a:=uAB;
       Simplex.Vertices[1]^.a:=vAB;
       Simplex.Divisor:=uAB+vAB;
       Simplex.Count:=2;
      end;
     end;
    end;
   end;
   3:begin
    // Triangle
    a:=Simplex.Vertices[0]^.w;
    b:=Simplex.Vertices[1]^.w;
    c:=Simplex.Vertices[2]^.w;
    vAB:=Vector3Dot(a,Vector3Sub(a,b));
    uCA:=Vector3Dot(a,Vector3Sub(a,c));
    if (vAB<=0.0) and (uCA<=0.0) then begin
     // Region A
     Simplex.Vertices[0]^.a:=1.0;
     Simplex.Divisor:=1.0;
     Simplex.Count:=1;
    end else begin
     ba:=Vector3Sub(b,a);
     uAB:=Vector3Dot(b,ba);
     vBC:=Vector3Dot(b,Vector3Sub(b,c));
     if (uAB<=0.0) and (vBC<=0.0) then begin
      // Region B
      TempVertex:=Simplex.Vertices[0];
      Simplex.Vertices[0]:=Simplex.Vertices[1];
      Simplex.Vertices[1]:=TempVertex;
      Simplex.Vertices[0]^.a:=1.0;
      Simplex.Divisor:=1.0;
      Simplex.Count:=1;
     end else begin
      uBC:=Vector3Dot(c,Vector3Sub(c,b));
      ca:=Vector3Sub(c,a);
      vCA:=Vector3Dot(c,ca);
      if (uBC<=0.0) and (vCA<=0.0) then begin
       // Region C
       TempVertex:=Simplex.Vertices[0];
       Simplex.Vertices[0]:=Simplex.Vertices[2];
       Simplex.Vertices[2]:=TempVertex;
       Simplex.Vertices[0]^.a:=1.0;
       Simplex.Divisor:=1.0;
       Simplex.Count:=1;
      end else begin
       baxca:=Vector3Cross(ba,ca);
       wABC:=Vector3Dot(Vector3Cross(a,b),baxca);
       if (uAB>0.0) and (vAB>0.0) and (wABC<=0.0) then begin
        // Region AB
        Simplex.Vertices[0]^.a:=uAB;
        Simplex.Vertices[1]^.a:=vAB;
        Simplex.Divisor:=uAB+vAB;
        Simplex.Count:=2;
       end else begin
        uABC:=Vector3Dot(Vector3Cross(b,c),baxca);
        if (uBC>0.0) and (vBC>0.0) and (uABC<=0.0) then begin
         // Region BC
         TempVertex:=Simplex.Vertices[0];
         Simplex.Vertices[0]:=Simplex.Vertices[1];
         Simplex.Vertices[1]:=Simplex.Vertices[2];
         Simplex.Vertices[2]:=TempVertex;
         Simplex.Vertices[0]^.a:=uBC;
         Simplex.Vertices[1]^.a:=vBC;
         Simplex.Divisor:=uBC+vBC;
         Simplex.Count:=2;
        end else begin
         vABC:=Vector3Dot(Vector3Cross(c,a),baxca);
         if (uCA>0.0) and (vCA>0.0) and (vABC<=0.0) then begin
          // Region CA
          TempVertex:=Simplex.Vertices[1];
          Simplex.Vertices[1]:=Simplex.Vertices[0];
          Simplex.Vertices[0]:=Simplex.Vertices[2];
          Simplex.Vertices[2]:=TempVertex;
          Simplex.Vertices[0]^.a:=uCA;
          Simplex.Vertices[1]^.a:=vCA;
          Simplex.Divisor:=uCA+vCA;
          Simplex.Count:=2;
         end else begin
          if (uABC>0.0) and (vABC>0.0) and (wABC>0.0) then begin
           // Region ABC
           Simplex.Vertices[0]^.a:=uABC;
           Simplex.Vertices[1]^.a:=vABC;
           Simplex.Vertices[2]^.a:=wABC;
           Simplex.Divisor:=uABC+vABC+wABC;
           Simplex.Count:=3;
          end else begin
           Assert(false);
          end;
         end;
        end;
       end;
      end;
     end;
    end;
   end;
   4:begin
    // Tetrahedron
    a:=Simplex.Vertices[0]^.w;
    b:=Simplex.Vertices[1]^.w;
    c:=Simplex.Vertices[2]^.w;
    d:=Simplex.Vertices[3]^.w;
    ab:=Vector3Sub(a,b);
    ac:=Vector3Sub(a,c);
    ad:=Vector3Sub(a,d);
    vAB:=Vector3Dot(a,ab);
    uCA:=Vector3Dot(a,ac);
    vAD:=Vector3Dot(a,ad);
    if (vAB<=0.0) and (uCA<=0.0) and (vAD<=0.0) then begin
     // Region A
     Simplex.Vertices[0]^.a:=1.0;
     Simplex.Divisor:=1.0;
     Simplex.Count:=1;
    end else begin
     ba:=Vector3Sub(b,a);
     bc:=Vector3Sub(b,c);
     bd:=Vector3Sub(b,d);
     uAB:=Vector3Dot(b,ba);
     vBC:=Vector3Dot(b,bc);
     vBD:=Vector3Dot(b,bd);
     if (uAB<=0.0) and (vBC<=0.0) and (vBD<=0.0) then begin
      // Region B
      TempVertex:=Simplex.Vertices[0];
      Simplex.Vertices[0]:=Simplex.Vertices[1];
      Simplex.Vertices[1]:=TempVertex;
      Simplex.Vertices[0]^.a:=1.0;
      Simplex.Divisor:=1.0;
      Simplex.Count:=1;
     end else begin
      cb:=Vector3Sub(c,b);
      ca:=Vector3Sub(c,a);
      dc:=Vector3Sub(d,c);
      uBC:=Vector3Dot(c,cb);
      vCA:=Vector3Dot(c,ca);
      uDC:=Vector3Dot(c,cd);
      if (uBC<=0.0) and (vCA<=0.0) and (uDC<=0.0) then begin
       // Region C
       TempVertex:=Simplex.Vertices[0];
       Simplex.Vertices[0]:=Simplex.Vertices[2];
       Simplex.Vertices[2]:=TempVertex;
       Simplex.Vertices[0]^.a:=1.0;
       Simplex.Divisor:=1.0;
       Simplex.Count:=1;
      end else begin
       db:=Vector3Sub(d,b);
       cd:=Vector3Sub(c,d);
       da:=Vector3Sub(d,a);
       uBD:=Vector3Dot(d,db);
       vDC:=Vector3Dot(d,dc);
       uAD:=Vector3Dot(d,da);
       if (uBD<=0.0) and (vDC<=0.0) and (uAD<=0.0) then begin
        // Region D
        TempVertex:=Simplex.Vertices[0];
        Simplex.Vertices[0]:=Simplex.Vertices[3];
        Simplex.Vertices[3]:=TempVertex;
        Simplex.Vertices[0]^.a:=1.0;
        Simplex.Divisor:=1.0;
        Simplex.Count:=1;
       end else begin
        baxca:=Vector3Cross(ba,ca);
        daxba:=Vector3Cross(da,ba);
        wABC:=Vector3Dot(Vector3Cross(a,b),baxca);
        vADB:=Vector3Dot(Vector3Cross(b,a),daxba);
        if (wABC<=0.0) and (vADB<=0.0) and (uAB>0.0) and (vAB>0.0) then begin
         // Region AB
         Simplex.Vertices[0]^.a:=uAB;
         Simplex.Vertices[1]^.a:=vAB;
         Simplex.Divisor:=uAB+vAB;
         Simplex.Count:=2;
        end else begin
         bcxdc:=Vector3Cross(bc,dc);
         uABC:=Vector3Dot(Vector3Cross(b,c),baxca);
         wCBD:=Vector3Dot(Vector3Cross(c,b),bcxdc);
         if (uABC<=0.0) and (wCBD<=0.0) and (uBC>0.0) and (vBC>0.0) then begin
          // Region BC
          TempVertex:=Simplex.Vertices[0];
          Simplex.Vertices[0]:=Simplex.Vertices[1];
          Simplex.Vertices[1]:=Simplex.Vertices[2];
          Simplex.Vertices[2]:=TempVertex;
          Simplex.Vertices[0]^.a:=uBC;
          Simplex.Vertices[1]^.a:=vBC;
          Simplex.Divisor:=uBC+vBC;
          Simplex.Count:=2;
         end else begin
          caxda:=Vector3Cross(ca,da);
          vABC:=Vector3Dot(Vector3Cross(c,a),baxca);
          wACD:=Vector3Dot(Vector3Cross(a,c),caxda);
          if (vABC<=0.0) and (wACD<=0.0) and (uCA>0.0) and (vCA>0.0) then begin
           // Region CA
           TempVertex:=Simplex.Vertices[1];
           Simplex.Vertices[1]:=Simplex.Vertices[0];
           Simplex.Vertices[0]:=Simplex.Vertices[2];
           Simplex.Vertices[2]:=TempVertex;
           Simplex.Vertices[0]^.a:=uCA;
           Simplex.Vertices[1]^.a:=vCA;
           Simplex.Divisor:=uCA+vCA;
           Simplex.Count:=2;
          end else begin
           vCBD:=Vector3Dot(Vector3Cross(d,c),bcxdc);
           uACD:=Vector3Dot(Vector3Cross(c,d),caxda);
           if (vCBD<=0.0) and (uACD<=0.0) and (uDC>0.0) and (vDC>0.0) then begin
            // Region DC
            TempVertex:=Simplex.Vertices[0];
            Simplex.Vertices[0]:=Simplex.Vertices[3];
            Simplex.Vertices[3]:=TempVertex;
            TempVertex:=Simplex.Vertices[1];
            Simplex.Vertices[1]:=Simplex.Vertices[2];
            Simplex.Vertices[2]:=TempVertex;
            Simplex.Vertices[0]^.a:=uDC;
            Simplex.Vertices[1]^.a:=vDC;
            Simplex.Divisor:=uDC+vDC;
            Simplex.Count:=2;
           end else begin
            vACD:=Vector3Dot(Vector3Cross(d,a),caxda);
            wADB:=Vector3Dot(Vector3Cross(a,d),daxba);
            if (vACD<=0.0) and (wADB<=0.0) and (uAD>0.0) and (vAD>0.0) then begin
             // Region AD
             TempVertex:=Simplex.Vertices[1];
             Simplex.Vertices[1]:=Simplex.Vertices[3];
             Simplex.Vertices[3]:=TempVertex;
             Simplex.Vertices[0]^.a:=uAD;
             Simplex.Vertices[1]^.a:=vAD;
             Simplex.Divisor:=uAD+vAD;
             Simplex.Count:=2;
            end else begin
             uADB:=Vector3Dot(Vector3Cross(d,b),daxba);
             uCBD:=Vector3Dot(Vector3Cross(b,d),bcxdc);
             if (uCBD<=0.0) and (uADB<=0.0) and (uBD>0.0) and (vBD>0.0) then begin
              // Region BD
              TempVertex:=Simplex.Vertices[0];
              Simplex.Vertices[0]:=Simplex.Vertices[1];
              Simplex.Vertices[1]:=Simplex.Vertices[3];
              Simplex.Vertices[3]:=TempVertex;
              Simplex.Vertices[0]^.a:=uBD;
              Simplex.Vertices[1]^.a:=vBD;
              Simplex.Divisor:=uBD+vBD;
              Simplex.Count:=2;
             end else begin
              Denominator:=Vector3Dot(cb,Vector3Cross(ab,db));
              if abs(Denominator)<EPSILON then begin
               Denominator:=1.0;
              end else begin
               Denominator:=1.0/Denominator;
              end;
              xABCD:=Vector3Dot(b,Vector3Cross(a,c))*Denominator;
              if (xABCD<=0.0) and (uABC>0.0) and (vABC>0.0) and (wABC>0.0) then begin
               // Region ABC
               Simplex.Vertices[0]^.a:=uABC;
               Simplex.Vertices[1]^.a:=vABC;
               Simplex.Vertices[2]^.a:=wABC;
               Simplex.Divisor:=uABC+vABC+wABC;
               Simplex.Count:=3;
              end else begin
               uABCD:=Vector3Dot(c,Vector3Cross(d,b))*Denominator;
               if (uABCD<=0.0) and (uCBD>0.0) and (vCBD>0.0) and (vCBD>0.0) then begin
                // Region CBD
                TempVertex:=Simplex.Vertices[0];
                Simplex.Vertices[0]:=Simplex.Vertices[2];
                Simplex.Vertices[2]:=Simplex.Vertices[3];
                Simplex.Vertices[3]:=TempVertex;
                Simplex.Vertices[0]^.a:=uCBD;
                Simplex.Vertices[1]^.a:=vCBD;
                Simplex.Vertices[2]^.a:=wCBD;
                Simplex.Divisor:=uCBD+vCBD+wCBD;
                Simplex.Count:=3;
               end else begin
                vABCD:=Vector3Dot(c,Vector3Cross(a,d))*Denominator;
                if (vABCD<=0.0) and (uACD>0.0) and (vACD>0.0) and (wACD>0.0) then begin
                 // Region ACD
                 TempVertex:=Simplex.Vertices[1];
                 Simplex.Vertices[1]:=Simplex.Vertices[2];
                 Simplex.Vertices[2]:=Simplex.Vertices[3];
                 Simplex.Vertices[3]:=TempVertex;
                 Simplex.Vertices[0]^.a:=uACD;
                 Simplex.Vertices[1]^.a:=vACD;
                 Simplex.Vertices[2]^.a:=wACD;
                 Simplex.Divisor:=uACD+vACD+wACD;
                 Simplex.Count:=3;
                end else begin
                 wABCD:=Vector3Dot(d,Vector3Cross(a,b))*Denominator;
                 if (wABCD<=0.0) and (uADB>0.0) and (vADB>0.0) and (wADB>0.0) then begin
                  // Region ADB
                  TempVertex:=Simplex.Vertices[2];
                  Simplex.Vertices[2]:=Simplex.Vertices[1];
                  Simplex.Vertices[1]:=Simplex.Vertices[3];
                  Simplex.Vertices[3]:=TempVertex;
                  Simplex.Vertices[0]^.a:=uADB;
                  Simplex.Vertices[1]^.a:=vADB;
                  Simplex.Vertices[2]^.a:=wADB;
                  Simplex.Divisor:=uADB+vADB+wADB;
                  Simplex.Count:=3;
                 end else begin
                  if (uABCD>0.0) and (vABCD>0.0) and (wABCD>0.0) and (xABCD>0.0) then begin
                   // Region ABCD
                   Simplex.Vertices[0]^.a:=uABCD;
                   Simplex.Vertices[1]^.a:=vABCD;
                   Simplex.Vertices[2]^.a:=wABCD;
                   Simplex.Vertices[3]^.a:=xABCD;
                   Simplex.Divisor:=uABCD+vABCD+wABCD+xABCD;
                   Simplex.Count:=4;
                   // Tetrahedron simplex contained the origin, so we can break the loop here
                   break;
                  end else begin
                   // The algorithm was unable to determine the subset, return the last best known subset
                   Simplex.Vertices[0]^.a:=uABC;
                   Simplex.Vertices[1]^.a:=vABC;
                   Simplex.Vertices[2]^.a:=wABC;
                   Simplex.Divisor:=uABC+vABC+wABC;
                   Simplex.Count:=3;
                  end;
                 end;
                end;
               end;
              end;
             end;
            end;
           end;
          end;
         end;
        end;
       end;
      end;
     end;
    end;
   end;
   else begin
    Assert(false);
   end;
  end;

  Assert(((Simplex.Vertices[0]<>Simplex.Vertices[1]) and (Simplex.Vertices[0]<>Simplex.Vertices[2]) and (Simplex.Vertices[0]<>Simplex.Vertices[3])) and ((Simplex.Vertices[1]<>Simplex.Vertices[2]) and (Simplex.Vertices[1]<>Simplex.Vertices[3])) and (Simplex.Vertices[2]<>Simplex.Vertices[3]));

  // Get closest point
  Denominator:=1.0/Simplex.Divisor;
  case Simplex.Count of
   1:begin
    a:=Simplex.Vertices[0]^.w;
   end;
   2:begin
    a:=Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.w,Simplex.Vertices[0]^.a*Denominator),
                  Vector3ScalarMul(Simplex.Vertices[1]^.w,Simplex.Vertices[1]^.a*Denominator));
   end;
   3:begin
    a:=Vector3Add(Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.w,Simplex.Vertices[0]^.a*Denominator),
                             Vector3ScalarMul(Simplex.Vertices[1]^.w,Simplex.Vertices[1]^.a*Denominator)),
                             Vector3ScalarMul(Simplex.Vertices[2]^.w,Simplex.Vertices[2]^.a*Denominator));
   end;
   4:begin
    a:=Vector3Add(Vector3Add(Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.w,Simplex.Vertices[0]^.a*Denominator),
                                        Vector3ScalarMul(Simplex.Vertices[1]^.w,Simplex.Vertices[1]^.a*Denominator)),
                                        Vector3ScalarMul(Simplex.Vertices[2]^.w,Simplex.Vertices[2]^.a*Denominator)),
                                        Vector3ScalarMul(Simplex.Vertices[3]^.w,Simplex.Vertices[3]^.a*Denominator));
   end;
   else begin
    Assert(false);
    a:=Vector3Origin;
   end;
  end;

  // Ensure progress. This prevents complex multi-step cycling between simplex evolutions (this is possible in 3D, but not in 2D).
  SquaredDistances[1]:=Vector3LengthSquared(a);
  if SquaredDistances[1]>SquaredDistances[0] then begin
   break;
  end;
  SquaredDistances[0]:=SquaredDistances[1];

  // Get next direction
  case Simplex.Count of
   1:begin
    Direction:=Vector3Neg(Simplex.Vertices[0]^.w);
   end;
   2:begin
    Direction:=Vector3Sub(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w);
    Direction:=Vector3Cross(Vector3Cross(Direction,Vector3Neg(Simplex.Vertices[0]^.w)),Direction);
   end;
   3:begin
    Direction:=Vector3Cross(Vector3Sub(Simplex.Vertices[1]^.w,Simplex.Vertices[0]^.w),Vector3Sub(Simplex.Vertices[2]^.w,Simplex.Vertices[0]^.w));
    if Vector3Dot(Direction,Simplex.Vertices[0]^.w)>0.0 then begin
     Direction:=Vector3Neg(Direction);
    end;
   end;
   else begin
    Assert(false);
    Direction:=Vector3Origin;
   end;
  end;

  if Vector3LengthSquared(Direction)<EPSILON then begin
   // The origin is probably contained by a line segment or triangle. Thus the shapes are overlapped.
   // We can't return zero here even though there may be overlap.
   // In case the simplex is a point, segment, or triangle it is difficult to determine if the origin is
   // contained in the CSO or very close to it.
   break;
  end;

  // Get new support simplex vertex indices
  iA:=Shapes[0].GetLocalFeatureSupportIndex(Vector3TermMatrixMulTransposedBasis(Vector3Neg(Direction),Transforms[0]^));
  iB:=Shapes[1].GetLocalFeatureSupportIndex(Vector3TermMatrixMulTransposedBasis(Direction,Transforms[1]^));

  inc(Iterations);

  // Check for duplicate support points
  Duplicate:=false;
  for Index:=0 to CountSaved-1 do begin
   if (Saved[Index,0]=iA) and (Saved[Index,1]=iB) then begin
    Duplicate:=true;
    break;
   end;
  end;
  if Duplicate then begin
   // If yes, then break the loop
   break;
  end;

  // Store the new stuff
  SimplexVertex:=Simplex.Vertices[Simplex.Count];
  SimplexVertex^.iA:=iA;
  SimplexVertex^.iB:=iB;
  SimplexVertex^.sA:=Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(iA),Transforms[0]^);
  SimplexVertex^.sB:=Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(iB),Transforms[1]^);
  SimplexVertex^.w:=Vector3Sub(SimplexVertex^.sB,SimplexVertex^.sA);
  inc(Simplex.Count);

 until Iterations=GJKMaximumIterations;

 // Write the simplex information into the cache
 if assigned(CachedSimplex) then begin
  CachedSimplex^.Count:=Simplex.Count;
  if CachedSimplex^.Count>0 then begin
   for Index:=0 to CachedSimplex^.Count-1 do begin
    CachedSimplexVertex:=@CachedSimplex^.Vertices[Index];
    SimplexVertex:=Simplex.Vertices[Index];
    CachedSimplexVertex^.iA:=SimplexVertex^.iA;
    CachedSimplexVertex^.iB:=SimplexVertex^.iB;
    CachedSimplexVertex^.a:=SimplexVertex^.a;
   end;
   case Simplex.Count of
    1:begin
     CachedSimplex^.Metric:=0.0;
    end;
    2:begin
     CachedSimplex^.Metric:=Vector3Dist(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w);
    end;
    3:begin
     CachedSimplex^.Metric:=CalculateArea(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w,Simplex.Vertices[2]^.w);
    end;
    4:begin
     CachedSimplex^.Metric:=CalculateVolume(Simplex.Vertices[0]^.w,Simplex.Vertices[1]^.w,Simplex.Vertices[2]^.w,Simplex.Vertices[3]^.w);
    end;
    else begin
     Assert(false);
     CachedSimplex^.Metric:=0.0;
    end;
   end;
  end;
 end;

 // Get closest points
 Denominator:=1.0/Simplex.Divisor;
 case Simplex.Count of
  1:begin
   ClosestPoints[0]:=Simplex.Vertices[0]^.sA;
   ClosestPoints[1]:=Simplex.Vertices[0]^.sB;
  end;
  2:begin
   ClosestPoints[0]:=Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.sA,Simplex.Vertices[0]^.a*Denominator),
                                Vector3ScalarMul(Simplex.Vertices[1]^.sA,Simplex.Vertices[1]^.a*Denominator));
   ClosestPoints[1]:=Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.sB,Simplex.Vertices[0]^.a*Denominator),
                                Vector3ScalarMul(Simplex.Vertices[1]^.sB,Simplex.Vertices[1]^.a*Denominator));
  end;
  3:begin
   ClosestPoints[0]:=Vector3Add(Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.sA,Simplex.Vertices[0]^.a*Denominator),
                                           Vector3ScalarMul(Simplex.Vertices[1]^.sA,Simplex.Vertices[1]^.a*Denominator)),
                                           Vector3ScalarMul(Simplex.Vertices[2]^.sA,Simplex.Vertices[2]^.a*Denominator));
   ClosestPoints[1]:=Vector3Add(Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.sB,Simplex.Vertices[0]^.a*Denominator),
                                           Vector3ScalarMul(Simplex.Vertices[1]^.sB,Simplex.Vertices[1]^.a*Denominator)),
                                           Vector3ScalarMul(Simplex.Vertices[2]^.sB,Simplex.Vertices[2]^.a*Denominator));
  end;
  4:begin
   ClosestPoints[0]:=Vector3Add(Vector3Add(Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.sA,Simplex.Vertices[0]^.a*Denominator),
                                                      Vector3ScalarMul(Simplex.Vertices[1]^.sA,Simplex.Vertices[1]^.a*Denominator)),
                                                      Vector3ScalarMul(Simplex.Vertices[2]^.sA,Simplex.Vertices[2]^.a*Denominator)),
                                                      Vector3ScalarMul(Simplex.Vertices[3]^.sA,Simplex.Vertices[3]^.a*Denominator));
   ClosestPoints[1]:=Vector3Add(Vector3Add(Vector3Add(Vector3ScalarMul(Simplex.Vertices[0]^.sB,Simplex.Vertices[0]^.a*Denominator),
                                                      Vector3ScalarMul(Simplex.Vertices[1]^.sB,Simplex.Vertices[1]^.a*Denominator)),
                                                      Vector3ScalarMul(Simplex.Vertices[2]^.sB,Simplex.Vertices[2]^.a*Denominator)),
                                                      Vector3ScalarMul(Simplex.Vertices[3]^.sB,Simplex.Vertices[3]^.a*Denominator));
  end;
  else begin
   Assert(false);
   ClosestPoints[0]:=Vector3Origin;
   ClosestPoints[1]:=Vector3Origin;
  end;
 end;

 // Get the normal direction
 Normal:=Vector3Sub(ClosestPoints[0],ClosestPoints[1]);

 // Normalize normal direction to a normalized normal vector, and get the distance at the same time
 Distance:=Vector3LengthNormalize(Normal);

 // Apply the radius stuff, if requested and needed
 if UseRadii then begin
  if (Distance>(Shapes[0].FeatureRadius+Shapes[1].FeatureRadius)) and (Distance>EPSILON) then begin
   Distance:=Distance-(Shapes[0].FeatureRadius+Shapes[1].FeatureRadius);
   ClosestPoints[0]:=Vector3Sub(ClosestPoints[0],Vector3ScalarMul(Normal,Shapes[0].FeatureRadius));
   ClosestPoints[1]:=Vector3Add(ClosestPoints[1],Vector3ScalarMul(Normal,Shapes[1].FeatureRadius));
  end else begin
   Distance:=0.0;
   ClosestPoints[0]:=Vector3Avg(ClosestPoints[0],ClosestPoints[1]);
   ClosestPoints[1]:=ClosestPoints[0];
  end;
 end;

 Failed:=((Simplex.Count<1) or (Simplex.Count>3)) or (Iterations=GJKMaximumIterations);

 result:=not Failed;

end;

procedure CalculateVelocity(const cA:TKraftVector3;const qA:TKraftQuaternion;const cB:TKraftVector3;const qB:TKraftQuaternion;const DeltaTime:TKraftScalar;var LinearVelocity,AngularVelocity:TKraftVector3); {$ifdef caninline}inline;{$endif}
var InverseDeltaTime,Angle:TKraftScalar;
    Axis:TKraftVector3;
    qD,qS,qB0:TKraftQuaternion;
begin
 InverseDeltaTime:=1.0/DeltaTime;
 LinearVelocity:=Vector3ScalarMul(Vector3Sub(cB,cA),InverseDeltaTime);
 if (abs(qA.x-qB.x)<EPSILON) and (abs(qA.y-qB.y)<EPSILON) and (abs(qA.z-qB.z)<EPSILON) and (abs(qA.w-qB.w)<EPSILON) then begin
  AngularVelocity:=Vector3Origin;
 end else begin
  qD:=QuaternionSub(qA,qB);
  qS:=QuaternionAdd(qA,qB);
  if QuaternionLengthSquared(qD)<QuaternionLengthSquared(qS) then begin
   qB0:=qD;
  end else begin
   qB0:=QuaternionNeg(qD);
  end;
  qD:=QuaternionMul(qB0,QuaternionInverse(qA));
  QuaternionToAxisAngle(qD,Axis,Angle);
  AngularVelocity:=Vector3ScalarMul(Vector3SafeNorm(Axis),Angle*InverseDeltaTime);
 end;
end;

constructor TKraftDynamicAABBTree.Create;
var i:longint;
begin
 inherited Create;
 Root:=daabbtNULLNODE;
 NodeCount:=0;
 NodeCapacity:=16;
 GetMem(Nodes,NodeCapacity*SizeOf(TKraftDynamicAABBTreeNode));
 FillChar(Nodes^,NodeCapacity*SizeOf(TKraftDynamicAABBTreeNode),#0);
 for i:=0 to NodeCapacity-2 do begin
  Nodes^[i].Next:=i+1;
  Nodes^[i].Height:=-1;
 end;
 Nodes^[NodeCapacity-1].Next:=daabbtNULLNODE;
 Nodes^[NodeCapacity-1].Height:=-1;
 FreeList:=0;
 Path:=0;
 InsertionCount:=0;
 StackCapacity:=16;
 GetMem(Stack,StackCapacity*SizeOf(longint));
end;

destructor TKraftDynamicAABBTree.Destroy;
begin
 FreeMem(Nodes);
 FreeMem(Stack);
 inherited Destroy;
end;

function TKraftDynamicAABBTree.AllocateNode:longint;
var Node:PKraftDynamicAABBTreeNode;
    i:longint;
begin
 if FreeList=daabbtNULLNODE then begin
  inc(NodeCapacity,NodeCapacity);
  ReallocMem(Nodes,NodeCapacity*SizeOf(TKraftDynamicAABBTreeNode));
  FillChar(Nodes^[NodeCount],(NodeCapacity-NodeCount)*SizeOf(TKraftDynamicAABBTreeNode),#0);
  for i:=NodeCount to NodeCapacity-2 do begin
   Nodes^[i].Next:=i+1;
   Nodes^[i].Height:=-1;
  end;
  Nodes^[NodeCapacity-1].Next:=daabbtNULLNODE;
  Nodes^[NodeCapacity-1].Height:=-1;
  FreeList:=NodeCount;
 end;
 result:=FreeList;
 FreeList:=Nodes^[result].Next;
 Node:=@Nodes^[result];
 Node^.Parent:=daabbtNULLNODE;
 Node^.Children[0]:=daabbtNULLNODE;
 Node^.Children[1]:=daabbtNULLNODE;
 Node^.Height:=0;
 Node^.UserData:=nil;
 inc(NodeCount);
end;

procedure TKraftDynamicAABBTree.FreeNode(NodeID:longint);
var Node:PKraftDynamicAABBTreeNode;
begin
 Node:=@Nodes^[NodeID];
 Node^.Next:=FreeList;
 Node^.Height:=-1;
 FreeList:=NodeID;
 dec(NodeCount);
end;

function TKraftDynamicAABBTree.Balance(NodeAID:longint):longint;
var NodeA,NodeB,NodeC,NodeD,NodeE,NodeF,NodeG:PKraftDynamicAABBTreeNode;
    NodeBID,NodeCID,NodeDID,NodeEID,NodeFID,NodeGID,NodeBalance:longint;
begin
 NodeA:=@Nodes^[NodeAID];
 if (NodeA.Children[0]<0) or (NodeA^.Height<2) then begin
  result:=NodeAID;
 end else begin
  NodeBID:=NodeA^.Children[0];
  NodeCID:=NodeA^.Children[1];
  NodeB:=@Nodes^[NodeBID];
  NodeC:=@Nodes^[NodeCID];
  NodeBalance:=NodeC^.Height-NodeB^.Height;
  if NodeBalance>1 then begin
   NodeFID:=NodeC^.Children[0];
   NodeGID:=NodeC^.Children[1];
   NodeF:=@Nodes^[NodeFID];
   NodeG:=@Nodes^[NodeGID];
   NodeC^.Children[0]:=NodeAID;
   NodeC^.Parent:=NodeA^.Parent;
   NodeA^.Parent:=NodeCID;
   if NodeC^.Parent>=0 then begin
    if Nodes^[NodeC^.Parent].Children[0]=NodeAID then begin
     Nodes^[NodeC^.Parent].Children[0]:=NodeCID;
    end else begin
     Nodes^[NodeC^.Parent].Children[1]:=NodeCID;
    end;
   end else begin
    Root:=NodeCID;
   end;
   if NodeF^.Height>NodeG^.Height then begin
    NodeC^.Children[1]:=NodeFID;
    NodeA^.Children[1]:=NodeGID;
    NodeG^.Parent:=NodeAID;
    NodeA^.AABB:=AABBCombine(NodeB^.AABB,NodeG^.AABB);
    NodeC^.AABB:=AABBCombine(NodeA^.AABB,NodeF^.AABB);
    NodeA^.Height:=1+Max(NodeB^.Height,NodeG^.Height);
    NodeC^.Height:=1+Max(NodeA^.Height,NodeF^.Height);
   end else begin
    NodeC^.Children[1]:=NodeGID;
    NodeA^.Children[1]:=NodeFID;
    NodeF^.Parent:=NodeAID;
    NodeA^.AABB:=AABBCombine(NodeB^.AABB,NodeF^.AABB);
    NodeC^.AABB:=AABBCombine(NodeA^.AABB,NodeG^.AABB);
    NodeA^.Height:=1+Max(NodeB^.Height,NodeF^.Height);
    NodeC^.Height:=1+Max(NodeA^.Height,NodeG^.Height);
   end;
   result:=NodeCID;
  end else if NodeBalance<-1 then begin
   NodeDID:=NodeB^.Children[0];
   NodeEID:=NodeB^.Children[1];
   NodeD:=@Nodes^[NodeDID];
   NodeE:=@Nodes^[NodeEID];
   NodeB^.Children[0]:=NodeAID;
   NodeB^.Parent:=NodeA^.Parent;
   NodeA^.Parent:=NodeBID;
   if NodeB^.Parent>=0 then begin
    if Nodes^[NodeB^.Parent].Children[0]=NodeAID then begin
     Nodes^[NodeB^.Parent].Children[0]:=NodeBID;
    end else begin
     Nodes^[NodeB^.Parent].Children[1]:=NodeBID;
    end;
   end else begin
    Root:=NodeBID;
   end;
   if NodeD^.Height>NodeE^.Height then begin
    NodeB^.Children[1]:=NodeDID;
    NodeA^.Children[0]:=NodeEID;
    NodeE^.Parent:=NodeAID;
    NodeA^.AABB:=AABBCombine(NodeC^.AABB,NodeE^.AABB);
    NodeB^.AABB:=AABBCombine(NodeA^.AABB,NodeD^.AABB);
    NodeA^.Height:=1+Max(NodeC^.Height,NodeE^.Height);
    NodeB^.Height:=1+Max(NodeA^.Height,NodeD^.Height);
   end else begin
    NodeB^.Children[1]:=NodeEID;
    NodeA^.Children[0]:=NodeDID;
    NodeD^.Parent:=NodeAID;
    NodeA^.AABB:=AABBCombine(NodeC^.AABB,NodeD^.AABB);
    NodeB^.AABB:=AABBCombine(NodeA^.AABB,NodeE^.AABB);
    NodeA^.Height:=1+Max(NodeC^.Height,NodeD^.Height);
    NodeB^.Height:=1+Max(NodeA^.Height,NodeE^.Height);
   end;
   result:=NodeBID;
  end else begin
   result:=NodeAID;
  end;
 end;
end;

procedure TKraftDynamicAABBTree.InsertLeaf(Leaf:longint);
var Node:PKraftDynamicAABBTreeNode;
    LeafAABB,CombinedAABB,AABB:TKraftAABB;
    Index,Sibling,OldParent,NewParent:longint;
    Children:array[0..1] of longint;
    CombinedCost,Cost,InheritanceCost:TKraftScalar;
    Costs:array[0..1] of TKraftScalar;
begin
 inc(InsertionCount);
 if Root<0 then begin
  Root:=Leaf;
  Nodes^[Leaf].Parent:=daabbtNULLNODE;
 end else begin
  LeafAABB:=Nodes^[Leaf].AABB;
  Index:=Root;
  while Nodes^[Index].Children[0]>=0 do begin
   Children[0]:=Nodes^[Index].Children[0];
   Children[1]:=Nodes^[Index].Children[1];

   CombinedAABB:=AABBCombine(Nodes^[Index].AABB,LeafAABB);
   CombinedCost:=AABBCost(CombinedAABB);
   Cost:=CombinedCost*2.0;
   InheritanceCost:=2.0*(CombinedCost-AABBCost(Nodes^[Index].AABB));

   AABB:=AABBCombine(LeafAABB,Nodes^[Children[0]].AABB);
   if Nodes^[Children[0]].Children[0]<0 then begin
    Costs[0]:=AABBCost(AABB)+InheritanceCost;
   end else begin
    Costs[0]:=(AABBCost(AABB)-AABBCost(Nodes^[Children[0]].AABB))+InheritanceCost;
   end;

   AABB:=AABBCombine(LeafAABB,Nodes^[Children[1]].AABB);
   if Nodes^[Children[1]].Children[1]<0 then begin
    Costs[1]:=AABBCost(AABB)+InheritanceCost;
   end else begin
    Costs[1]:=(AABBCost(AABB)-AABBCost(Nodes^[Children[1]].AABB))+InheritanceCost;
   end;

   if (Cost<Costs[0]) and (Cost<Costs[1]) then begin
    break;
   end else begin
    if Costs[0]<Costs[1] then begin
     Index:=Children[0];
    end else begin
     Index:=Children[1];
    end;
   end;

  end;

  Sibling:=Index;

  OldParent:=Nodes^[Sibling].Parent;
  NewParent:=AllocateNode;
  Nodes^[NewParent].Parent:=OldParent;
  Nodes^[NewParent].UserData:=nil;
  Nodes^[NewParent].AABB:=AABBCombine(LeafAABB,Nodes^[Sibling].AABB);
  Nodes^[NewParent].Height:=Nodes^[Sibling].Height+1;

  if OldParent>=0 then begin
   if Nodes^[OldParent].Children[0]=Sibling then begin
    Nodes^[OldParent].Children[0]:=NewParent;
   end else begin
    Nodes^[OldParent].Children[1]:=NewParent;
   end;
   Nodes^[NewParent].Children[0]:=Sibling;
   Nodes^[NewParent].Children[1]:=Leaf;
   Nodes^[Sibling].Parent:=NewParent;
   Nodes^[Leaf].Parent:=NewParent;
  end else begin
   Nodes^[NewParent].Children[0]:=Sibling;
   Nodes^[NewParent].Children[1]:=Leaf;
   Nodes^[Sibling].Parent:=NewParent;
   Nodes^[Leaf].Parent:=NewParent;
   Root:=NewParent;
  end;

  Index:=Nodes^[Leaf].Parent;
  while Index>=0 do begin
   Index:=Balance(Index);
   Node:=@Nodes^[Index];
   Node^.AABB:=AABBCombine(Nodes^[Node^.Children[0]].AABB,Nodes^[Node^.Children[1]].AABB);
   Node^.Height:=1+Max(Nodes^[Node^.Children[0]].Height,Nodes^[Node^.Children[1]].Height);
   Index:=Node^.Parent;
  end;

 end;
end;

procedure TKraftDynamicAABBTree.RemoveLeaf(Leaf:longint);
var Node:PKraftDynamicAABBTreeNode;
    Parent,GrandParent,Sibling,Index:longint;
begin
 if Root=Leaf then begin
  Root:=daabbtNULLNODE;
 end else begin
  Parent:=Nodes^[Leaf].Parent;
  GrandParent:=Nodes^[Parent].Parent;
  if Nodes^[Parent].Children[0]=Leaf then begin
   Sibling:=Nodes^[Parent].Children[1];
  end else begin
   Sibling:=Nodes^[Parent].Children[0];
  end;
  if GrandParent>=0 then begin
   if Nodes^[GrandParent].Children[0]=Parent then begin
    Nodes^[GrandParent].Children[0]:=Sibling;
   end else begin
    Nodes^[GrandParent].Children[1]:=Sibling;
   end;
   Nodes^[Sibling].Parent:=GrandParent;
   FreeNode(Parent);
   Index:=GrandParent;
   while Index>=0 do begin
    Index:=Balance(Index);
    Node:=@Nodes^[Index];
    Node^.AABB:=AABBCombine(Nodes^[Node^.Children[0]].AABB,Nodes^[Node^.Children[1]].AABB);
    Node^.Height:=1+Max(Nodes^[Node^.Children[0]].Height,Nodes^[Node^.Children[1]].Height);
    Index:=Node^.Parent;
   end;
  end else begin
   Root:=Sibling;
   Nodes^[Sibling].Parent:=daabbtNULLNODE;
   FreeNode(Parent);
  end;
 end;
end;

function TKraftDynamicAABBTree.CreateProxy(const AABB:TKraftAABB;UserData:pointer):longint;
var Node:PKraftDynamicAABBTreeNode;
begin
 result:=AllocateNode;
 Node:=@Nodes^[result];
 Node^.AABB.Min:=Vector3Sub(AABB.Min,AABBExtensionVector);
 Node^.AABB.Max:=Vector3Add(AABB.Max,AABBExtensionVector);
 Node^.UserData:=UserData;
 Node^.Height:=0;
 InsertLeaf(result);
end;

procedure TKraftDynamicAABBTree.DestroyProxy(NodeID:longint);
begin
 RemoveLeaf(NodeID);
 FreeNode(NodeID);
end;

function TKraftDynamicAABBTree.MoveProxy(NodeID:longint;const AABB:TKraftAABB;const Displacement,BoundsExpansion:TKraftVector3):boolean;
var Node:PKraftDynamicAABBTreeNode;
    b:TKraftAABB;
    d:TKraftVector3;
begin
 Node:=@Nodes^[NodeID];
 result:=not AABBContains(Node^.AABB,AABB);
 if result then begin
  RemoveLeaf(NodeID);
  d:=Vector3Add(AABBExtensionVector,BoundsExpansion);
  b.Min:=Vector3Sub(AABB.Min,d);
  b.Max:=Vector3Add(AABB.Max,d);
  d:=Vector3ScalarMul(Displacement,AABB_MULTIPLIER);
  if d.x<0.0 then begin
   b.Min.x:=b.Min.x+d.x;
  end else if d.x>0.0 then begin
   b.Max.x:=b.Max.x+d.x;
  end;
  if d.y<0.0 then begin
   b.Min.y:=b.Min.y+d.y;
  end else if d.y>0.0 then begin
   b.Max.y:=b.Max.y+d.y;
  end;
  if d.z<0.0 then begin
   b.Min.z:=b.Min.z+d.z;
  end else if d.z>0.0 then begin
   b.Max.z:=b.Max.z+d.z;
  end;
  Node^.AABB:=b;//AABBStretch(AABB,Displacement,BoundsExpansions);
  InsertLeaf(NodeID);
 end;
end;

procedure TKraftDynamicAABBTree.Rebalance(Iterations:longint);
var Counter,Node:longint;
    Bit:longword;
//  Children:PKraftDynamicAABBTreeLongintArray;
begin
 if (Root>=0) and (Root<NodeCount) then begin
  for Counter:=1 to Iterations do begin
   Bit:=0;
   Node:=Root;
   while Nodes[Node].Children[0]>=0 do begin
    Node:=Nodes[Node].Children[(Path shr Bit) and 1];
    Bit:=(Bit+1) and 31;
   end;
   inc(Path);
   if ((Node>=0) and (Node<NodeCount)) and (Nodes[Node].Children[0]<0) then begin
    RemoveLeaf(Node);
    InsertLeaf(Node);
   end else begin
    break;
   end;
  end;
 end;
end;

procedure TKraftDynamicAABBTree.Rebuild;
var NewNodes:PKraftDynamicAABBTreeLongintArray;
    Children:array[0..1] of PKraftDynamicAABBTreeNode;
    Parent:PKraftDynamicAABBTreeNode;
    Count,i,j,iMin,jMin,Index1,Index2,ParentIndex:longint;
    MinCost,Cost:TKraftScalar;
    AABBi,AABBj:PKraftAABB;
    AABB:TKraftAABB;
    First:boolean;
begin
 if NodeCount>0 then begin
  NewNodes:=nil;
  GetMem(NewNodes,NodeCount*SizeOf(longint));
  FillChar(NewNodes^,NodeCount*SizeOf(longint),#0);
  Count:=0;
  for i:=0 to NodeCapacity-1 do begin
   if Nodes^[i].Height>=0 then begin
    if Nodes^[i].Children[0]<0 then begin
     Nodes^[i].Parent:=daabbtNULLNODE;
     NewNodes^[Count]:=i;
     inc(Count);
    end else begin
     FreeNode(i);
    end;
   end;
  end;
  while Count>1 do begin
   First:=true;
   MinCost:=3.4e+38;
   iMin:=-1;
   jMin:=-1;
 {}/////////////////TOOPTIMIZE///////////////////
 {}for i:=0 to Count-1 do begin                //
 {} AABBi:=@Nodes^[NewNodes^[i]].AABB;         //
 {} for j:=i+1 to Count-1 do begin             //
 {}  AABBj:=@Nodes^[NewNodes^[j]].AABB;        //
 {}  AABB:=AABBCombine(AABBi^,AABBj^);         //
 {}  Cost:=AABBCost(AABB);                     //
 {}  if First or (Cost<MinCost) then begin     //
 {}   First:=false;                            //
 {}   MinCost:=Cost;                           //
 {}   iMin:=i;                                 //
 {}   jMin:=j;                                 //
 {}  end;                                      //
 {} end;                                       //
 {}end;                                        //
 {}/////////////////TOOPTIMIZE///////////////////
   Index1:=NewNodes^[iMin];
   Index2:=NewNodes^[jMin];
   Children[0]:=@Nodes^[Index1];
   Children[1]:=@Nodes^[Index2];
   ParentIndex:=AllocateNode;
   Parent:=@Nodes^[ParentIndex];
   Parent^.Children[0]:=Index1;
   Parent^.Children[1]:=Index2;
   Parent^.Height:=1+Max(Children[0]^.Height,Children[1]^.Height);
   Parent^.AABB:=AABBCombine(Children[0]^.AABB,Children[1]^.AABB);
   Parent^.Parent:=daabbtNULLNODE;
   Children[0]^.Parent:=ParentIndex;
   Children[1]^.Parent:=ParentIndex;
   NewNodes^[jMin]:=NewNodes^[Count-1];
   NewNodes^[iMin]:=ParentIndex;
   dec(Count);
  end;
  Root:=NewNodes^[0];
  FreeMem(NewNodes);
 end;
end;

function TKraftDynamicAABBTree.ComputeHeight:longint;
var LocalStack:PKraftDynamicAABBTreeLongintArray;
    LocalStackPointer,NodeID,Height:longint;
    Node:PKraftDynamicAABBTreeNode;
begin
 result:=0;
 if Root>=0 then begin
  LocalStack:=Stack;
  LocalStack^[0]:=Root;
  LocalStack^[1]:=1;
  LocalStackPointer:=2;
  while LocalStackPointer>0 do begin
   dec(LocalStackPointer,2);
   NodeID:=LocalStack^[LocalStackPointer];
   Height:=LocalStack^[LocalStackPointer+1];
   if result<Height then begin
    result:=Height;
   end;
   if NodeID>=0 then begin
    Node:=@Nodes^[NodeID];
    if Node^.Children[0]>=0 then begin
     if StackCapacity<=(LocalStackPointer+4) then begin
      StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+4);
      ReallocMem(Stack,StackCapacity*SizeOf(longint));
      LocalStack:=Stack;
     end;
     LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
     LocalStack^[LocalStackPointer+1]:=Height+1;
     LocalStack^[LocalStackPointer+2]:=Node^.Children[1];
     LocalStack^[LocalStackPointer+3]:=Height+1;
     inc(LocalStackPointer,4);
    end;
   end;
  end;
 end;
end;

function TKraftDynamicAABBTree.GetHeight:longint;
begin
 if Root>=0 then begin
  result:=Nodes[Root].Height;
 end else begin
  result:=0;
 end;
end;

function TKraftDynamicAABBTree.GetAreaRatio:TKraftScalar;
var NodeID:longint;
    Node:PKraftDynamicAABBTreeNode;
begin
 result:=0;
 if Root>=0 then begin
  for NodeID:=0 to NodeCount-1 do begin
   Node:=@Nodes[NodeID];
   if Node^.Height>=0 then begin
    result:=result+AABBCost(Node^.AABB);
   end;
  end;
  result:=result/AABBCost(Nodes[Root].AABB);
 end;
end;

function TKraftDynamicAABBTree.GetMaxBalance:longint;
var NodeID,Balance:longint;
    Node:PKraftDynamicAABBTreeNode;
begin
 result:=0;
 for NodeID:=0 to NodeCount-1 do begin
  Node:=@Nodes[NodeID];
  if (Node^.Height>1) and (Node^.Children[0]>=0) then begin
   Balance:=abs(Nodes[Node^.Children[1]].Height-Nodes[Node^.Children[0]].Height);
   if result<Balance then begin
    result:=Balance;
   end;
  end;
 end;
end;

function TKraftDynamicAABBTree.ValidateStructure:boolean;
var LocalStack:PKraftDynamicAABBTreeLongintArray;
    LocalStackPointer,NodeID,Parent:longint;
    Node:PKraftDynamicAABBTreeNode;
begin
 result:=true;
 if Root>=0 then begin
  LocalStack:=Stack;
  LocalStack^[0]:=Root;
  LocalStack^[1]:=-1;
  LocalStackPointer:=2;
  while LocalStackPointer>0 do begin
   dec(LocalStackPointer,2);
   NodeID:=LocalStack^[LocalStackPointer];
   Parent:=LocalStack^[LocalStackPointer+1];
   if (NodeID>=0) and (NodeID<NodeCount) then begin
    Node:=@Nodes^[NodeID];
    if Node^.Parent<>Parent then begin
     result:=false;
     break;
    end;
    if Node^.Children[0]<0 then begin
     if (Node^.Children[1]>=0) or (Node^.Height<>0) then begin
      result:=false;
      break;
     end;
    end else begin
     if StackCapacity<=(LocalStackPointer+4) then begin
      StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+4);
      ReallocMem(Stack,StackCapacity*SizeOf(longint));
      LocalStack:=Stack;
     end;
     LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
     LocalStack^[LocalStackPointer+1]:=NodeID;
     LocalStack^[LocalStackPointer+2]:=Node^.Children[1];
     LocalStack^[LocalStackPointer+3]:=NodeID;
     inc(LocalStackPointer,4);
    end;
   end else begin
    result:=false;
    break;
   end;
  end;
 end;
end;

function TKraftDynamicAABBTree.ValidateMetrics:boolean;
var LocalStack:PKraftDynamicAABBTreeLongintArray;
    LocalStackPointer,NodeID{,Height}:longint;
    Node:PKraftDynamicAABBTreeNode;
    AABB:TKraftAABB;
begin
 result:=true;
 if Root>=0 then begin
  LocalStack:=Stack;
  LocalStack^[0]:=Root;
  LocalStackPointer:=1;
  while LocalStackPointer>0 do begin
   dec(LocalStackPointer);
   NodeID:=LocalStack^[LocalStackPointer];
   if (NodeID>=0) and (NodeID<NodeCount) then begin
    Node:=@Nodes^[NodeID];
    if Node^.Children[0]>=0 then begin
     if (((Node^.Children[0]<0) or (Node^.Children[0]>=NodeCount)) or
         ((Node^.Children[1]<0) or (Node^.Children[1]>=NodeCount))) or
        (Node^.Height<>(1+Max(Nodes[Node^.Children[0]].Height,Nodes[Node^.Children[1]].Height))) then begin
      result:=false;
      break;
     end;
     AABB:=AABBCombine(Nodes[Node^.Children[0]].AABB,Nodes[Node^.Children[1]].AABB);
     if not (Vector3Compare(Node^.AABB.Min,AABB.Min) and Vector3Compare(Node^.AABB.Max,AABB.Max)) then begin
      result:=false;
      break;
     end;
     if StackCapacity<=(LocalStackPointer+2) then begin
      StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+2);
      ReallocMem(Stack,StackCapacity*SizeOf(longint));
      LocalStack:=Stack;
     end;
     LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
     LocalStack^[LocalStackPointer+1]:=Node^.Children[1];
     inc(LocalStackPointer,2);
    end;
   end else begin
    result:=false;
    break;
   end;
  end;
 end;
end;

function TKraftDynamicAABBTree.Validate:boolean;
var NodeID,FreeCount:longint;
begin
 result:=ValidateStructure;
 if result then begin
  result:=ValidateMetrics;
  if result then begin
   result:=ComputeHeight=GetHeight;
   if result then begin
    NodeID:=FreeList;
    FreeCount:=0;
    while NodeID>=0 do begin
     NodeID:=Nodes[NodeID].Next;
     inc(FreeCount);
    end;
    result:=(NodeCount+FreeCount)=NodeCapacity;
   end;
  end;
 end;
end;

function TKraftDynamicAABBTree.GetIntersectionProxy(const AABB:TKraftAABB):pointer;
var LocalStack:PKraftDynamicAABBTreeLongintArray;
    LocalStackPointer,NodeID:longint;
    Node:PKraftDynamicAABBTreeNode;
begin
 result:=nil;
 if Root>=0 then begin
  LocalStack:=Stack;
  LocalStack^[0]:=Root;
  LocalStackPointer:=1;
  while LocalStackPointer>0 do begin
   dec(LocalStackPointer);
   NodeID:=LocalStack^[LocalStackPointer];
   if NodeID>=0 then begin
    Node:=@Nodes[NodeID];
    if AABBIntersect(Node^.AABB,AABB) then begin
     if Node^.Children[0]<0 then begin
      result:=Node^.UserData;
      exit;
     end else begin
      if StackCapacity<=(LocalStackPointer+2) then begin
       StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+2);
       ReallocMem(Stack,StackCapacity*SizeOf(longint));
       LocalStack:=Stack;
      end;
      LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
      LocalStack^[LocalStackPointer+1]:=Node^.Children[1];
      inc(LocalStackPointer,2);
     end;
    end;
   end;
  end;
 end;
end;

type PConvexHullVector=^TConvexHullVector;
     TConvexHullVector=record
      x,y,z:double;
     end;

     TConvexHullPoints=array of TConvexHullVector;

     PConvexHullTriangle=^TConvexHullTriangle;
     TConvexHullTriangle=array[0..2] of longint;

     TConvexHullTriangles=array of TConvexHullTriangle;

function CompareConvexHullPoints(const a,b:pointer):longint;
 function IsSameValue(const a,b:double):boolean;
 const FuzzFactor=1000;
       DoubleResolution=1e-15*FuzzFactor;
 var EpsilonTolerance:double;
 begin
  EpsilonTolerance:=abs(a);
  if EpsilonTolerance>abs(b) then begin
   EpsilonTolerance:=abs(b);
  end;
  EpsilonTolerance:=EpsilonTolerance*DoubleResolution;
  if EpsilonTolerance<DoubleResolution then begin
   EpsilonTolerance:=DoubleResolution;
  end;
  if a>b then begin
   result:=(a-b)<=EpsilonTolerance;
  end else begin
   result:=(b-a)<=EpsilonTolerance;
  end;
 end;
var va,vb:PConvexHullVector;
begin
 va:=a;
 vb:=b;
 if (IsSameValue(va^.x,vb^.x) and ((IsSameValue(va^.y,vb^.y) and (va^.z>vb^.z)) or (va^.y>vb^.y))) or (va^.x>vb^.x) then begin
  result:=-1;
 end else if (IsSameValue(va^.x,vb^.x) and ((IsSameValue(va^.y,vb^.y) and (va^.z<vb^.z)) or (va^.y<vb^.y))) or (va^.x<vb^.x) then begin
  result:=1;
 end else begin
  result:=0;
 end;
end;

function GenerateConvexHull(var Points:TConvexHullPoints;var OutTriangles:TConvexHullTriangles;const MaximumOutputPoints:longint=-1):boolean;
const DOUBLE_PREC:double=2.2204460492503131e-16;
      EPSILON=1e-10;
type PTriangle=^TTriangle;
     TTriangle=record
      Vertices:array[0..2] of longint;
      PlaneNormal:TConvexHullVector;
      PlaneOffset:double;
      Deleted:longbool;
     end;
     TTriangles=array of TTriangle;
     PEdge=^TEdge;
     TEdge=record
      Vertices:array[0..1] of longint;
      Deleted:longbool;
     end;
     TEdges=array of TEdge;
var Triangles:TTriangles;
    CountTriangles:longint;
    ProcessedPointBitmap:array of longword;
    CountPoints:longint;
    Edges:TEdges;
    CountEdges:longint;
    DeletedTriangles:array of longint;
    CountDeletedTriangles:longint;
    MinPoint,MaxPoint:TConvexHullVector;
    Tolerance:double;
 function IsSameValue(const a,b:double):boolean;
 const FuzzFactor=1000;
       DoubleResolution=1e-15*FuzzFactor;
 var EpsilonTolerance:double;
 begin
  EpsilonTolerance:=abs(a);
  if EpsilonTolerance>abs(b) then begin
   EpsilonTolerance:=abs(b);
  end;
  EpsilonTolerance:=EpsilonTolerance*DoubleResolution;
  if EpsilonTolerance<DoubleResolution then begin
   EpsilonTolerance:=DoubleResolution;
  end;
  if a>b then begin
   result:=(a-b)<=EpsilonTolerance;
  end else begin
   result:=(b-a)<=EpsilonTolerance;
  end;
 end;
 function VectorCompare(const v1,v2:TConvexHullVector):boolean;
 begin
  result:=IsSameValue(v1.x,v2.x) and IsSameValue(v1.y,v2.y) and IsSameValue(v1.z,v2.z);
 end;
 function VectorSub(const v1,v2:TConvexHullVector):TConvexHullVector;
 begin
  result.x:=v1.x-v2.x;
  result.y:=v1.y-v2.y;
  result.z:=v1.z-v2.z;
 end;
 function VectorAdd(const v1,v2:TConvexHullVector):TConvexHullVector;
 begin
  result.x:=v1.x+v2.x;
  result.y:=v1.y+v2.y;
  result.z:=v1.z+v2.z;
 end;
 function VectorCross(const v1,v2:TConvexHullVector):TConvexHullVector;
 begin
  result.x:=(v1.y*v2.z)-(v1.z*v2.y);
  result.y:=(v1.z*v2.x)-(v1.x*v2.z);
  result.z:=(v1.x*v2.y)-(v1.y*v2.x);
 end;
 function VectorLengthSquared(const v:TConvexHullVector):double;
 begin
  result:=sqr(v.x)+sqr(v.y)+sqr(v.z);
 end;
 function VectorDot(const v1,v2:TConvexHullVector):double;
 begin
  result:=(v1.x*v2.x)+(v1.y*v2.y)+(v1.z*v2.z);
 end;
 function VectorNorm(const v:TConvexHullVector):TConvexHullVector;
 var l:double;
 begin
  l:=sqr(v.x)+sqr(v.y)+sqr(v.z);
  if l>EPSILON then begin
   l:=sqrt(l);
   result.x:=v.x/l;
   result.y:=v.y/l;
   result.z:=v.z/l;
  end else begin
   result.x:=0.0;
   result.y:=0.0;
   result.z:=0.0;
  end;
 end;
 function CalculateArea(const v0,v1,v2:TConvexHullVector):double;
 begin
  result:=VectorLengthSquared(VectorCross(VectorSub(v1,v0),VectorSub(v2,v0)));
 end;
 function CalculateVolume(const v0,v1,v2,v3:TConvexHullVector):double;
 var a,b,c:TConvexHullVector;
 begin
  a:=VectorSub(v0,v3);
  b:=VectorSub(v1,v3);
  c:=VectorSub(v2,v3);
  result:=(a.x*((b.z*c.y)-(b.y*c.z)))+(a.y*((b.x*c.z)-(b.z*c.x)))+(a.z*((b.y*c.x)-(b.x*c.y)));
 end;
 procedure RemoveDuplicatePoints;
 const HashBits=8;
       HashSize=1 shl HashBits;
       HashMask=HashSize-1;
 var PointIndex,OtherPointIndex,CountNewPoints,HashItemIndex:longint;
     Hash:longword;
     NewPoints:TConvexHullPoints;
     PointNextIndices:array of longint;
     HashTable:array of longint;
 begin
  NewPoints:=nil;
  PointNextIndices:=nil;
  HashTable:=nil;
  try

   SetLength(PointNextIndices,length(Points));
   for PointIndex:=0 to length(PointNextIndices)-1 do begin
    PointNextIndices[PointIndex]:=-1;
   end;

   SetLength(HashTable,HashSize);
   for PointIndex:=0 to length(HashTable)-1 do begin
    HashTable[PointIndex]:=-1;
   end;

   SetLength(NewPoints,length(Points));
   CountNewPoints:=0;

   for PointIndex:=0 to length(Points)-1 do begin

    Hash:=((round(Points[PointIndex].x)*73856093) xor (round(Points[PointIndex].y)*19349663) xor (round(Points[PointIndex].z)*83492791)) and HashMask;

    HashItemIndex:=HashTable[Hash];
    while HashItemIndex>=0 do begin
     if VectorCompare(Points[PointIndex],NewPoints[HashItemIndex]) then begin
      break;
     end;
     HashItemIndex:=PointNextIndices[HashItemIndex];
    end;

    if HashItemIndex<0 then begin
     OtherPointIndex:=CountNewPoints;
     inc(CountNewPoints);
     if CountNewPoints>length(NewPoints) then begin
      SetLength(NewPoints,CountNewPoints*2);
     end;
     NewPoints[OtherPointIndex]:=Points[PointIndex];
     PointNextIndices[OtherPointIndex]:=HashTable[Hash];
     HashTable[Hash]:=OtherPointIndex;
    end;

   end;

   if length(Points)<>CountNewPoints then begin
    SetLength(Points,CountNewPoints);
    for PointIndex:=0 to CountNewPoints-1 do begin
     Points[PointIndex]:=NewPoints[PointIndex];
    end;
   end;

  finally
   SetLength(NewPoints,0);
   SetLength(PointNextIndices,0);
   SetLength(HashTable,0);
  end;
 end;
 procedure SortPoints;
 var Count,Index:longint;
     NewPoints:TConvexHullPoints;
     IndirectPoints:array of PConvexHullVector;
 begin
  Count:=length(Points);
  if Count>1 then begin
   NewPoints:=nil;
   IndirectPoints:=nil;
   try
    NewPoints:=Points;
    Points:=nil;
    SetLength(IndirectPoints,Count);
    SetLength(Points,Count);
    for Index:=0 to Count-1 do begin
     IndirectPoints[Index]:=@NewPoints[Index];
    end;
    IndirectIntroSort(@IndirectPoints[0],0,Count-1,@CompareConvexHullPoints);
    for Index:=0 to Count-1 do begin
     Points[Index]:=IndirectPoints[Index]^;
    end;
   finally
    SetLength(NewPoints,0);
    SetLength(IndirectPoints,0);
   end;
  end;
 end;
 procedure RefillOnlyWithOutsideVisiblePoints;
 const HashBits=8;
       HashSize=1 shl HashBits;
       HashMask=HashSize-1;
 var TriangleIndex,TrianglePointIndex,PointIndex,OtherPointIndex,CountNewPoints,HashItemIndex:longint;
     Hash:longword;
     NewPoints:TConvexHullPoints;
     PointNextIndices:array of longint;
     HashTable:array of longint;
 begin
  NewPoints:=nil;
  PointNextIndices:=nil;
  HashTable:=nil;
  try

   SetLength(PointNextIndices,length(Points));
   for PointIndex:=0 to length(PointNextIndices)-1 do begin
    PointNextIndices[PointIndex]:=-1;
   end;

   SetLength(HashTable,HashSize);
   for PointIndex:=0 to length(HashTable)-1 do begin
    HashTable[PointIndex]:=-1;
   end;

   SetLength(NewPoints,length(Points));
   CountNewPoints:=0;

   for TriangleIndex:=0 to CountTriangles-1 do begin

    if not Triangles[TriangleIndex].Deleted then begin

     for TrianglePointIndex:=0 to 2 do begin

      PointIndex:=Triangles[TriangleIndex].Vertices[TrianglePointIndex];

      Hash:=((round(Points[PointIndex].x)*73856093) xor (round(Points[PointIndex].y)*19349663) xor (round(Points[PointIndex].z)*83492791)) and HashMask;

      HashItemIndex:=HashTable[Hash];
      while HashItemIndex>=0 do begin
       if VectorCompare(Points[PointIndex],NewPoints[HashItemIndex]) then begin
        break;
       end;
       HashItemIndex:=PointNextIndices[HashItemIndex];
      end;

      if HashItemIndex<0 then begin
       OtherPointIndex:=CountNewPoints;
       inc(CountNewPoints);
       if CountNewPoints>length(NewPoints) then begin
        SetLength(NewPoints,CountNewPoints*2);
       end;
       NewPoints[OtherPointIndex]:=Points[PointIndex];
       PointNextIndices[OtherPointIndex]:=HashTable[Hash];
       HashTable[Hash]:=OtherPointIndex;
      end else begin
       OtherPointIndex:=HashItemIndex;
      end;

      Triangles[TriangleIndex].Vertices[TrianglePointIndex]:=OtherPointIndex;

     end;

    end;

   end;

   if length(Points)<>CountNewPoints then begin
    SetLength(Points,CountNewPoints);
   end;
   for PointIndex:=0 to CountNewPoints-1 do begin
    Points[PointIndex]:=NewPoints[PointIndex];
   end;

  finally
   SetLength(NewPoints,0);
   SetLength(PointNextIndices,0);
   SetLength(HashTable,0);
  end;
 end;
 procedure AddTriangle(const v0,v1,v2:longint);
 var Index:longint;
     Triangle:PTriangle;
 begin
  if CountDeletedTriangles>0 then begin
   dec(CountDeletedTriangles);
   Index:=DeletedTriangles[CountDeletedTriangles];
  end else begin
   Index:=CountTriangles;
   inc(CountTriangles);
   if CountTriangles>=length(Triangles) then begin
    SetLength(Triangles,CountTriangles*2);
   end;
  end;
  Triangle:=@Triangles[Index];
  Triangle^.Vertices[0]:=v0;
  Triangle^.Vertices[1]:=v1;
  Triangle^.Vertices[2]:=v2;
  Triangle^.PlaneNormal:=VectorNorm(VectorCross(VectorSub(Points[v1],Points[v0]),VectorSub(Points[v2],Points[v0])));
  Triangle^.PlaneOffset:=-((Triangle^.PlaneNormal.x*Points[v0].x)+(Triangle^.PlaneNormal.y*Points[v0].y)+(Triangle^.PlaneNormal.z*Points[v0].z));
  Triangle^.Deleted:=false;
 end;
 function GetFirstTetrahedron:boolean;
 var PointIndex:longint;
     BestArea,Area,BestVolume,Volume:double;
     TempVertices:array[0..3] of longint;
 begin
  result:=false;

  TempVertices[0]:=0;
  TempVertices[3]:=0;
  for PointIndex:=0 to CountPoints-1 do begin
   if (Points[PointIndex].x<Points[TempVertices[0]].x) or
      (SameValue(Points[PointIndex].x,Points[TempVertices[0]].x) and
       ((Points[PointIndex].y<Points[TempVertices[0]].y) or
        (SameValue(Points[PointIndex].y,Points[TempVertices[0]].y) and
         (Points[PointIndex].z<Points[TempVertices[0]].z)))) then begin
    TempVertices[0]:=PointIndex;
   end;
   if (Points[PointIndex].x>Points[TempVertices[0]].x) or
      (SameValue(Points[PointIndex].x,Points[TempVertices[0]].x) and
       ((Points[PointIndex].y>Points[TempVertices[0]].y) or
        (SameValue(Points[PointIndex].y,Points[TempVertices[0]].y) and
         (Points[PointIndex].z>Points[TempVertices[0]].z)))) then begin
    TempVertices[3]:=PointIndex;
   end;
  end;
  if TempVertices[0]=TempVertices[3] then begin
   exit;
  end;

  TempVertices[1]:=0;
  BestArea:=abs(CalculateArea(Points[TempVertices[0]],Points[TempVertices[3]],Points[TempVertices[1]]));
  for PointIndex:=1 to CountPoints-1 do begin
   Area:=abs(CalculateArea(Points[TempVertices[0]],Points[TempVertices[3]],Points[PointIndex]));
   if BestArea<Area then begin
    BestArea:=Area;
    TempVertices[1]:=PointIndex;
   end;
  end;
  if (TempVertices[0]=TempVertices[1]) or (TempVertices[3]=TempVertices[1]) then begin
   exit;
  end;

  TempVertices[2]:=0;
  BestVolume:=CalculateVolume(Points[TempVertices[0]],Points[TempVertices[1]],Points[TempVertices[3]],Points[0]);
  for PointIndex:=1 to CountPoints-1 do begin
   Volume:=abs(CalculateVolume(Points[TempVertices[0]],Points[TempVertices[1]],Points[TempVertices[3]],Points[PointIndex]));
   if BestVolume<Volume then begin
    BestVolume:=Volume;
    TempVertices[2]:=PointIndex;
   end;
  end;
  if (TempVertices[0]=TempVertices[2]) or (TempVertices[1]=TempVertices[2]) or (TempVertices[3]=TempVertices[2]) then begin
   exit;
  end;

  for PointIndex:=0 to 3 do begin
   if CalculateVolume(Points[TempVertices[PointIndex and 3]],Points[TempVertices[(PointIndex+1) and 3]],Points[TempVertices[(PointIndex+2) and 3]],Points[TempVertices[(PointIndex+3) and 3]])>0 then begin
    AddTriangle(TempVertices[(PointIndex+1) and 3],TempVertices[PointIndex and 3],TempVertices[(PointIndex+2) and 3]);
   end else begin
    AddTriangle(TempVertices[PointIndex and 3],TempVertices[(PointIndex+1) and 3],TempVertices[(PointIndex+2) and 3]);
   end;

   ProcessedPointBitmap[TempVertices[PointIndex] shr 5]:=ProcessedPointBitmap[TempVertices[PointIndex] shr 5] or (longword(1) shl (TempVertices[PointIndex] and 31));

  end;

  result:=true;
 end;
 procedure PushEdge(v0,v1:longint);
 var EdgeIndex,ScanEdgeIndex:longint;
     Edge:PEdge;
 begin
  EdgeIndex:=-1;
  for ScanEdgeIndex:=0 to CountEdges-1 do begin
   Edge:=@Edges[ScanEdgeIndex];
   if Edge^.Deleted then begin
    if EdgeIndex<0 then begin
     EdgeIndex:=ScanEdgeIndex;
    end;
   end else if ((Edge^.Vertices[0]=v0) and (Edge^.Vertices[1]=v1)) or
               ((Edge^.Vertices[0]=v1) and (Edge^.Vertices[1]=v0)) then begin
    Edge^.Deleted:=true;
    exit;
   end;
  end;
  if EdgeIndex<0 then begin
   EdgeIndex:=CountEdges;
   inc(CountEdges);
   if CountEdges>=length(Edges) then begin
    SetLength(Edges,CountEdges*2);
   end;
  end;
  Edge:=@Edges[EdgeIndex];
  Edge^.Vertices[0]:=v0;
  Edge^.Vertices[1]:=v1;
  Edge^.Deleted:=false;
 end;
 procedure DeleteTriangle(TriangleIndex:longint);
 var DeletedTriangleIndex:longint;
 begin
  DeletedTriangleIndex:=CountDeletedTriangles;
  inc(CountDeletedTriangles);
  if CountDeletedTriangles>length(DeletedTriangles) then begin
   SetLength(DeletedTriangles,CountDeletedTriangles*2);
  end;
  DeletedTriangles[DeletedTriangleIndex]:=TriangleIndex;
  Triangles[TriangleIndex].Deleted:=true;
 end;
 procedure AddPoint(PointIndex:longint);
 const EdgeVertices:array[0..2,0..2] of longint=((0,1,2),(1,2,0),(2,0,1));
 var TriangleIndex,EdgeIndex:longint;
     Triangle:PTriangle;
     Edge:PEdge;
 begin
  if (ProcessedPointBitmap[PointIndex shr 5] and (longword(1) shl (PointIndex and 31)))=0 then begin
   ProcessedPointBitmap[PointIndex shr 5]:=ProcessedPointBitmap[PointIndex shr 5] or (longword(1) shl (PointIndex and 31));
   CountEdges:=0;
   for TriangleIndex:=0 to CountTriangles-1 do begin
    Triangle:=@Triangles[TriangleIndex];
    if (not Triangle^.Deleted) and ((VectorDot(Triangle^.PlaneNormal,Points[PointIndex])+Triangle^.PlaneOffset)>Tolerance) then begin
     for EdgeIndex:=0 to 2 do begin
      if CalculateVolume(Points[Triangle^.Vertices[EdgeVertices[EdgeIndex,0]]],Points[Triangle^.Vertices[EdgeVertices[EdgeIndex,1]]],Points[PointIndex],Points[Triangle^.Vertices[EdgeVertices[EdgeIndex,2]]])>0.0 then begin
       // Flipped triangle, correct the vertex order
       PushEdge(Triangle^.Vertices[EdgeVertices[EdgeIndex,1]],Triangle^.Vertices[EdgeVertices[EdgeIndex,0]]);
      end else begin
       // Non-flipped triangle, so we don't need to correct the vertex order here
       PushEdge(Triangle^.Vertices[EdgeVertices[EdgeIndex,0]],Triangle^.Vertices[EdgeVertices[EdgeIndex,1]]);
      end;
     end;
     DeleteTriangle(TriangleIndex);
    end;
   end;
   while CountEdges>0 do begin
    dec(CountEdges);
    Edge:=@Edges[CountEdges];
    if not Edge^.Deleted then begin
     AddTriangle(Edge^.Vertices[0],Edge^.Vertices[1],PointIndex);
    end;
   end;
  end;
 end;
 function GetFarthestOutsideHullUnprocessedPointIndex:longint;
 var PointIndex,TriangleIndex:longint;
     BestOverallDistance,BestPointDistance,Distance:double;
     Triangle:PTriangle;
     Valid:boolean;
 begin
  result:=-1;
  BestOverallDistance:=0.0;
  for PointIndex:=0 to CountPoints-1 do begin
   if (ProcessedPointBitmap[PointIndex shr 5] and (longword(1) shl (PointIndex and 31)))=0 then begin
    BestPointDistance:=0.0;
    Valid:=false;
    for TriangleIndex:=0 to CountTriangles-1 do begin
     Triangle:=@Triangles[TriangleIndex];
     if not Triangle^.Deleted then begin
      Distance:=VectorDot(Triangle^.PlaneNormal,Points[PointIndex]);
      if (Distance>Tolerance) and ((BestPointDistance<Distance) or not Valid) then begin
       BestPointDistance:=Distance;
       Valid:=true;
      end;
     end;
    end;
    if Valid and (BestOverallDistance<BestPointDistance) then begin
     BestOverallDistance:=BestPointDistance;
     result:=PointIndex;
    end;
   end;
  end;
 end;
 procedure Build;
 type PStackItem=^TStackItem;
      TStackItem=record
       Left,Right:longint;
      end;
      TStack=array[0..31] of TStackItem;
 var StackPointer,Left,Right,Split,PointIndex,PointsToDo:longint;
     StackItem:PStackItem;
     BestArea,Area:double;
     Stack:TStack;
 begin
  if GetFirstTetrahedron then begin
   PointsToDo:=MaximumOutputPoints-4;
  end else begin
   AddTriangle(0,1,2);
   AddTriangle(0,2,1);
   for PointIndex:=0 to 2 do begin
    ProcessedPointBitmap[PointIndex shr 5]:=ProcessedPointBitmap[PointIndex shr 5] or (longword(1) shl (PointIndex and 31));
   end;
   PointsToDo:=MaximumOutputPoints-3;
  end;
  if (MaximumOutputPoints<=0) or (MaximumOutputPoints>=CountPoints) then begin
   StackPointer:=0;
   StackItem:=@Stack[StackPointer];
   inc(StackPointer);
   StackItem^.Left:=0;
   StackItem^.Right:=CountPoints-1;
   while StackPointer>0 do begin
    dec(StackPointer);
    StackItem:=@Stack[StackPointer];
    Left:=StackItem^.Left;
    Right:=StackItem^.Right;
    if Left<=Right then begin
     if ((Right-Left)<=4) or (StackPointer>=29) then begin
      for PointIndex:=Left to Right do begin
       AddPoint(PointIndex);
      end;
     end else begin
      Split:=Left+((Right-Left) shr 1);
      BestArea:=abs(CalculateArea(Points[Left],Points[Right],Points[Split]));
      for PointIndex:=Left+1 to Right-1 do begin
       Area:=abs(CalculateArea(Points[Left],Points[Right],Points[PointIndex]));
       if BestArea<Area then begin
        BestArea:=Area;
        Split:=PointIndex;
       end;
      end;
      AddPoint(Left);
      AddPoint(Split);
      AddPoint(Right);
      if (Split+1)<=(Right-1) then begin
       StackItem:=@Stack[StackPointer];
       inc(StackPointer);
       StackItem^.Left:=Split+1;
       StackItem^.Right:=Right-1;
      end;
      if (Left+1)<=(Split-1) then begin
       StackItem:=@Stack[StackPointer];
       inc(StackPointer);
       StackItem^.Left:=Left+1;
       StackItem^.Right:=Split-1;
      end;
     end;
    end;
   end;
  end else begin
   while PointsToDo>0 do begin
    dec(PointsToDo);
    PointIndex:=GetFarthestOutsideHullUnprocessedPointIndex;
    if PointIndex<0 then begin
     break;
    end else begin
     AddPoint(PointIndex);
    end;
   end;
  end;
 end;
 procedure SearchMinMax;
 var Index:longint;
     Point:PConvexHullVector;
 begin
  MinPoint:=Points[0];
  MaxPoint:=Points[0];
  for Index:=1 to CountPoints-1 do begin
   Point:=@Points[Index];
   if MinPoint.x>Point^.x then begin
    MinPoint.x:=Point^.x;
   end;
   if MinPoint.y>Point^.y then begin
    MinPoint.y:=Point^.y;
   end;
   if MinPoint.z>Point^.z then begin
    MinPoint.z:=Point^.z;
   end;
   if MaxPoint.x<Point^.x then begin
    MaxPoint.x:=Point^.x;
   end;
   if MaxPoint.y<Point^.y then begin
    MaxPoint.y:=Point^.y;
   end;
   if MaxPoint.z<Point^.z then begin
    MaxPoint.z:=Point^.z;
   end;
  end;
 end;
var Index,TriangleIndex,TriangleVertexIndex,Count:longint;
    Triangle:PTriangle;
    OutTriangle:PConvexHullTriangle;
begin
 result:=false;

 Triangles:=nil;
 CountTriangles:=0;

 Edges:=nil;
 CountEdges:=0;

 DeletedTriangles:=nil;
 CountDeletedTriangles:=0;

 ProcessedPointBitmap:=nil;

 try

  SetLength(Triangles,64);
  SetLength(Edges,64);
  SetLength(DeletedTriangles,64);

  RemoveDuplicatePoints;

  SortPoints;

  CountPoints:=length(Points);

  if CountPoints=3 then begin

   AddTriangle(0,1,2);
   AddTriangle(0,2,1);

   result:=true;

  end else if (CountPoints=4) and (abs(CalculateVolume(Points[0],Points[1],Points[2],Points[3]))<1e-10) then begin

   AddTriangle(0,1,2);
   AddTriangle(2,3,0);
   AddTriangle(2,1,0);
   AddTriangle(0,3,2);

   result:=true;

  end else if CountPoints>=4 then begin

   SetLength(ProcessedPointBitmap,(CountPoints+31) shr 5);
   for Index:=0 to length(ProcessedPointBitmap)-1 do begin
    ProcessedPointBitmap[Index]:=0;
   end;

   SearchMinMax;

   Tolerance:=(3.0*DOUBLE_PREC)*(abs(MaxPoint.x-MinPoint.x)+abs(MaxPoint.y-MinPoint.y)+abs(MaxPoint.z-MinPoint.z));

   Build;

   SetLength(Edges,0);
   SetLength(DeletedTriangles,0);

   RefillOnlyWithOutsideVisiblePoints;

   result:=true;
  end;

  if result then begin
   Count:=0;
   for TriangleIndex:=0 to CountTriangles-1 do begin
    Triangle:=@Triangles[TriangleIndex];
    if not Triangle^.Deleted then begin
     inc(Count);
    end;
   end;
   SetLength(OutTriangles,Count);
   Count:=0;
   for TriangleIndex:=0 to CountTriangles-1 do begin
    Triangle:=@Triangles[TriangleIndex];
    if not Triangle^.Deleted then begin
     OutTriangle:=@OutTriangles[Count];
     inc(Count);
     for TriangleVertexIndex:=0 to 2 do begin
      OutTriangle[TriangleVertexIndex]:=Triangle^.Vertices[TriangleVertexIndex];
     end;
    end;
   end;
  end else begin
   SetLength(OutTriangles,0);
  end;

 finally

  SetLength(ProcessedPointBitmap,0);
  SetLength(Triangles,0);
  SetLength(Edges,0);
  SetLength(DeletedTriangles,0);

 end;
end;

constructor TKraftConvexHull.Create(const APhysics:TKraft);
begin

 inherited Create;
                     
 Physics:=APhysics;

 Vertices:=nil;
 CountVertices:=0;

 Faces:=nil;
 CountFaces:=0;

 Edges:=nil;
 CountEdges:=0;

 FillChar(Sphere,SizeOf(TKraftSphere),AnsiChar(#0));

 FillChar(AABB,SizeOf(TKraftAABB),AnsiChar(#0));

 AngularMotionDisc:=0.0;

 if assigned(Physics.ConvexHullLast) then begin
  Physics.ConvexHullLast.Next:=self;
  Previous:=Physics.ConvexHullLast;
 end else begin
  Physics.ConvexHullFirst:=self;
  Previous:=nil;
 end;
 Physics.ConvexHullLast:=self;
 Next:=nil;

end;

destructor TKraftConvexHull.Destroy;
begin

 SetLength(Vertices,0);

 SetLength(Faces,0);

 SetLength(Edges,0);

 if assigned(Previous) then begin
  Previous.Next:=Next;
 end else if Physics.ConvexHullFirst=self then begin
  Physics.ConvexHullFirst:=Next;
 end;
 if assigned(Next) then begin
  Next.Previous:=Previous;
 end else if Physics.ConvexHullLast=self then begin
  Physics.ConvexHullLast:=Previous;
 end;
 Previous:=nil;
 Next:=nil;

 inherited Destroy;

end;

function TKraftConvexHull.AddVertex(const AVertex:TKraftVector3):longint;
var Vertex:PKraftConvexHullVertex;
begin
 result:=CountVertices;
 inc(CountVertices);
 if CountVertices>length(Vertices) then begin
  SetLength(Vertices,CountVertices*2);
 end;
 Vertex:=@Vertices[result];
 Vertex^.Position:=AVertex;
 Vertex^.CountAdjacencies:=0;
end;

procedure TKraftConvexHull.Load(const AVertices:PKraftVector3;const ACountVertices:longint);
var Index:longint;
    Vertex:PKraftConvexHullVertex;
begin
 CountVertices:=ACountVertices;
 SetLength(Vertices,CountVertices);
 for Index:=0 to CountVertices-1 do begin
  Vertex:=@Vertices[Index];
  Vertex^.Position:=PKraftVector3s(AVertices)^[Index];
  Vertex^.CountAdjacencies:=0;
 end;
end;

procedure TKraftConvexHull.Scale(const WithFactor:TKraftScalar);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3Scale(Vertices[Index].Position,WithFactor);
 end;
end;

procedure TKraftConvexHull.Scale(const WithVector:TKraftVector3);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3Scale(Vertices[Index].Position,WithVector.x,WithVector.y,WithVector.z);
 end;
end;

procedure TKraftConvexHull.Transform(const WithMatrix:TKraftMatrix3x3);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3MatrixMul(Vertices[Index].Position,WithMatrix);
 end;
end;

procedure TKraftConvexHull.Transform(const WithMatrix:TKraftMatrix4x4);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3MatrixMul(Vertices[Index].Position,WithMatrix);
 end;
end;

procedure TKraftConvexHull.Build(const AMaximumCountConvexHullPoints:longint=-1);
const HashBits=8;
      HashSize=1 shl HashBits;
      HashMask=HashSize-1;
      ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
type PTempFaceEdgeHashItem=^TTempFaceEdgeHashItem;
     TTempFaceEdgeHashItem=record
      Next:longint;
      Hash:longword;
      Edge:longint;
      Face:longint;
      FaceEdge:longint;
      FaceEdgeVertexA:longint;
      FaceEdgeVertexB:longint;
     end;
     PTempFaceEdge=^TTempFaceEdge;
     TTempFaceEdge=record
      Face:longint;
      Twin:longint;
      Vertices:array[0..1] of longint;
     end;    
var CountTriangles,PointIndex,TriangleIndex,TriangleVertexIndex,VertexIndex,OtherVertexIndex,OtherTriangleIndex,
    OtherTriangleVertexIndex,SearchIndex,CountTempFaceEdges,FaceIndex,EdgeVertexOffset,TempFaceEdgeIndex,
    OtherTempFaceEdgeIndex,CountTempFaceEdgeHashItems,TempFaceEdgeHashItemIndex,v0,v1,v2:longint;
    TempFaceEdgeHash:longword;
    TempFaceEdgeHashItem:PTempFaceEdgeHashItem;
    TempPoints:TConvexHullPoints;
    TempTriangles:TConvexHullTriangles;
    Vertex:PKraftConvexHullVertex;
    Face:PKraftConvexHullFace;
    Edge:PKraftConvexHullEdge;
    pa,pb:TKraftPlane;
    vn,NewPlaneNormal:TKraftVector3;
    Processed:array of boolean;
    TempFaceEdges:array of TTempFaceEdge;
    TempFaceEdge:PTempFaceEdge;
    Found:boolean;
    TempFaceEdgeHashItems:array of TTempFaceEdgeHashItem;
    TempFaceEdgeHashTable:array of longint;
begin
 Faces:=nil;
 CountFaces:=0;
 Edges:=nil;
 CountEdges:=0;

 TempPoints:=nil;
 TempTriangles:=nil;
 TempFaceEdges:=nil;
 TempFaceEdgeHashItems:=nil;
 TempFaceEdgeHashTable:=nil;
 try

  SetLength(TempPoints,CountVertices);
  for PointIndex:=0 to CountVertices-1 do begin
   TempPoints[PointIndex].x:=Vertices[PointIndex].Position.x;
   TempPoints[PointIndex].y:=Vertices[PointIndex].Position.y;
   TempPoints[PointIndex].z:=Vertices[PointIndex].Position.z;
  end;

  GenerateConvexHull(TempPoints,TempTriangles,AMaximumCountConvexHullPoints);

  CountVertices:=length(TempPoints);
  SetLength(Vertices,CountVertices);
  for PointIndex:=0 to CountVertices-1 do begin
   Vertices[PointIndex].Position.x:=TempPoints[PointIndex].x;
   Vertices[PointIndex].Position.y:=TempPoints[PointIndex].y;
   Vertices[PointIndex].Position.z:=TempPoints[PointIndex].z;
  end;

  CountTriangles:=length(TempTriangles);

  // Compute vertex adjacency
  for VertexIndex:=0 to CountVertices-1 do begin
   Vertices[VertexIndex].CountAdjacencies:=0;
  end;
  for TriangleIndex:=0 to CountTriangles-1 do begin
   for TriangleVertexIndex:=0 to 2 do begin
    VertexIndex:=TempTriangles[TriangleIndex,TriangleVertexIndex];
    Vertex:=@Vertices[VertexIndex];
    for OtherTriangleVertexIndex:=1 to 2 do begin
     OtherVertexIndex:=TempTriangles[TriangleIndex,ModuloThree[TriangleVertexIndex+OtherTriangleVertexIndex]];
     if Vertex^.CountAdjacencies<length(Vertex^.Adjacencies) then begin
      Found:=false;
      for SearchIndex:=0 to Vertex^.CountAdjacencies-1 do begin
       if Vertex^.Adjacencies[SearchIndex]=OtherVertexIndex then begin
        Found:=true;
        break;
       end;
      end;
      if not Found then begin
       Vertex^.Adjacencies[Vertex^.CountAdjacencies]:=OtherVertexIndex;
       inc(Vertex^.CountAdjacencies);
      end;
     end else begin
      break;
     end;
    end;
   end;
  end;

  // Construct unique face poylgons from coplanar triangles
  SetLength(Faces,CountTriangles);
  CountFaces:=0;
  CountTempFaceEdges:=0;
  EdgeVertexOffset:=0;
  SetLength(Processed,CountTriangles);
  for TriangleIndex:=0 to length(Processed)-1 do begin
   Processed[TriangleIndex]:=false;
  end;
  for TriangleIndex:=0 to CountTriangles-1 do begin
   if not Processed[TriangleIndex] then begin
    Processed[TriangleIndex]:=true;
    FaceIndex:=CountFaces;
    Face:=@Faces[FaceIndex];
    inc(CountFaces);
    SetLength(Face^.Vertices,3);
    Face^.Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[TempTriangles[TriangleIndex,1]].Position,Vertices[TempTriangles[TriangleIndex,0]].Position),Vector3Sub(Vertices[TempTriangles[TriangleIndex,2]].Position,Vertices[TempTriangles[TriangleIndex,0]].Position)));
    Face^.Plane.Distance:=-Vector3Dot(Face^.Plane.Normal,Vertices[TempTriangles[TriangleIndex,0]].Position);
    NewPlaneNormal:=Face^.Plane.Normal;
    pa:=Face^.Plane;
    Face^.EdgeVertexOffset:=EdgeVertexOffset;
    Face^.CountVertices:=3;
    Face^.Vertices[0]:=TempTriangles[TriangleIndex,0];
    Face^.Vertices[1]:=TempTriangles[TriangleIndex,1];
    Face^.Vertices[2]:=TempTriangles[TriangleIndex,2];
    for OtherTriangleIndex:=TriangleIndex+1 to CountTriangles-1 do begin
     if not Processed[OtherTriangleIndex] then begin
      pb.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[TempTriangles[OtherTriangleIndex,1]].Position,Vertices[TempTriangles[OtherTriangleIndex,0]].Position),Vector3Sub(Vertices[TempTriangles[OtherTriangleIndex,2]].Position,Vertices[TempTriangles[OtherTriangleIndex,0]].Position)));
      pb.Distance:=-Vector3Dot(Face^.Plane.Normal,Vertices[TempTriangles[OtherTriangleIndex,0]].Position);
      if (sqr(pb.Normal.x-pa.Normal.x)+sqr(pb.Normal.y-pa.Normal.y)+sqr(pb.Normal.z-pa.Normal.z)+sqr(pb.Distance-pa.Distance))<EPSILON then begin
       NewPlaneNormal:=Vector3Add(NewPlaneNormal,pb.Normal);
       Processed[OtherTriangleIndex]:=true;
       for OtherTriangleVertexIndex:=0 to 2 do begin
        Found:=false;
        for VertexIndex:=0 to Face^.CountVertices-1 do begin
         if Face^.Vertices[VertexIndex]=TempTriangles[OtherTriangleIndex,OtherTriangleVertexIndex] then begin
          Found:=true;
          break;
         end;
        end;
        if not Found then begin
         v1:=-1;
         for VertexIndex:=Face^.CountVertices-1 downto 0 do begin
          v0:=VertexIndex;
          v2:=VertexIndex+1;
          if v2>=Face^.CountVertices then begin
           dec(v2,Face^.CountVertices);
          end;
          if Vector3Dot(Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[TempTriangles[OtherTriangleIndex,OtherTriangleVertexIndex]].Position,
                                                              Vertices[Face^.Vertices[v0]].Position),
                                                   Vector3Sub(Vertices[Face^.Vertices[v2]].Position,
                                                              Vertices[Face^.Vertices[v0]].Position))),Face^.Plane.Normal)>0.0 then begin
           v1:=v2;
           break;
          end;
         end;
         VertexIndex:=Face^.CountVertices;
         inc(Face^.CountVertices);
         if Face^.CountVertices>length(Face^.Vertices) then begin
          SetLength(Face^.Vertices,Face^.CountVertices*2);
         end;
         if v1>=0 then begin
          if v1<(Face^.CountVertices-1) then begin
           for VertexIndex:=Face^.CountVertices-1 downto v1+1 do begin
            Face^.Vertices[VertexIndex]:=Face^.Vertices[VertexIndex-1];
           end;
          end;
          Face^.Vertices[v1]:=TempTriangles[OtherTriangleIndex,OtherTriangleVertexIndex];
         end else begin
          Face^.Vertices[VertexIndex]:=TempTriangles[OtherTriangleIndex,OtherTriangleVertexIndex];
         end;
        end;
       end;
      end;
     end;
    end;
    inc(EdgeVertexOffset,Face^.CountVertices);
    if length(Face^.Vertices)<>Face^.CountVertices then begin
     SetLength(Face^.Vertices,Face^.CountVertices);
    end;
    if Face^.CountVertices>3 then begin
     VertexIndex:=0;
     while VertexIndex<Face^.CountVertices do begin
      v0:=VertexIndex-1;
      if v0<0 then begin
       inc(v0,Face^.CountVertices);
      end;
      v1:=VertexIndex;
      v2:=VertexIndex+1;
      if v2>=Face^.CountVertices then begin
       dec(v2,Face^.CountVertices);
      end;
      if Vector3Dot(Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[Face^.Vertices[v1]].Position,Vertices[Face^.Vertices[v0]].Position),Vector3Sub(Vertices[Face^.Vertices[v2]].Position,Vertices[Face^.Vertices[v0]].Position))),Face^.Plane.Normal)<0.0 then begin
       v0:=Face^.Vertices[v1];
       Face^.Vertices[v1]:=Face^.Vertices[v2];
       Face^.Vertices[v2]:=v0;
       if VertexIndex>0 then begin
        dec(VertexIndex);
       end else begin
        inc(VertexIndex);
       end;
      end else begin
       inc(VertexIndex);
      end;
     end;
    end;
    Face^.Plane.Normal:=Vector3NormEx(NewPlaneNormal);
    Face^.Plane.Distance:=-Vector3Dot(Face^.Plane.Normal,Vertices[Face^.Vertices[0]].Position);
    for VertexIndex:=0 to Face^.CountVertices-1 do begin
     OtherVertexIndex:=VertexIndex+1;
     if OtherVertexIndex>=Face^.CountVertices then begin
      dec(OtherVertexIndex,Face^.CountVertices);
     end;
     TempFaceEdgeIndex:=CountTempFaceEdges;
     inc(CountTempFaceEdges);
     if CountTempFaceEdges>length(TempFaceEdges) then begin
      SetLength(TempFaceEdges,CountTempFaceEdges*2);
     end;
     TempFaceEdge:=@TempFaceEdges[TempFaceEdgeIndex];
     TempFaceEdge^.Face:=FaceIndex;
     TempFaceEdge^.Vertices[0]:=Face^.Vertices[VertexIndex];
     TempFaceEdge^.Vertices[1]:=Face^.Vertices[OtherVertexIndex];
    end;
   end;
  end;
  SetLength(Faces,CountFaces);
  SetLength(TempFaceEdges,CountTempFaceEdges);

  // Find unique edges
  try
   SetLength(Edges,CountTempFaceEdges);
   SetLength(TempFaceEdgeHashItems,CountTempFaceEdges);
   SetLength(TempFaceEdgeHashTable,HashSize);
   for TempFaceEdgeHashItemIndex:=0 to HashSize-1 do begin
    TempFaceEdgeHashTable[TempFaceEdgeHashItemIndex]:=-1;
   end;
   CountTempFaceEdgeHashItems:=0;
   for TempFaceEdgeIndex:=0 to CountTempFaceEdges-1 do begin
    TempFaceEdge:=@TempFaceEdges[TempFaceEdgeIndex];
    if TempFaceEdge^.Vertices[0]<TempFaceEdge^.Vertices[1] then begin
     TempFaceEdgeHash:=(longword(TempFaceEdge^.Vertices[0])*73856093) xor (longword(TempFaceEdge^.Vertices[1])*83492791);
    end else begin
     TempFaceEdgeHash:=(longword(TempFaceEdge^.Vertices[1])*73856093) xor (longword(TempFaceEdge^.Vertices[0])*83492791);
    end;
    TempFaceEdgeHashItemIndex:=TempFaceEdgeHashTable[TempFaceEdgeHash and HashMask];
    while TempFaceEdgeHashItemIndex>=0 do begin
     TempFaceEdgeHashItem:=@TempFaceEdgeHashItems[TempFaceEdgeHashItemIndex];
     if (TempFaceEdgeHashItem^.Hash=TempFaceEdgeHash) and
        (((TempFaceEdgeHashItem^.FaceEdgeVertexA=TempFaceEdge^.Vertices[0]) and (TempFaceEdgeHashItem^.FaceEdgeVertexB=TempFaceEdge^.Vertices[1])) or
         ((TempFaceEdgeHashItem^.FaceEdgeVertexA=TempFaceEdge^.Vertices[1]) and (TempFaceEdgeHashItem^.FaceEdgeVertexB=TempFaceEdge^.Vertices[0]))) then begin
      break;
     end else begin
      TempFaceEdgeHashItemIndex:=TempFaceEdgeHashItem^.Next;
     end;
    end;
    if TempFaceEdgeHashItemIndex<0 then begin
     if length(TempFaceEdgeHashItems)<(CountTempFaceEdgeHashItems+1) then begin
      SetLength(TempFaceEdgeHashItems,(CountTempFaceEdgeHashItems+1)*2);
     end;
     TempFaceEdgeHashItem:=@TempFaceEdgeHashItems[CountTempFaceEdgeHashItems];
     TempFaceEdgeHashItem^.Next:=TempFaceEdgeHashTable[TempFaceEdgeHash and HashMask];
     TempFaceEdgeHashTable[TempFaceEdgeHash and HashMask]:=CountTempFaceEdgeHashItems;
     TempFaceEdgeHashItem^.Hash:=TempFaceEdgeHash;
     inc(CountTempFaceEdgeHashItems);
     TempFaceEdgeHashItem^.Edge:=-1;
     TempFaceEdgeHashItem^.Face:=TempFaceEdge^.Face;
     TempFaceEdgeHashItem^.FaceEdge:=TempFaceEdgeIndex;
     TempFaceEdgeHashItem^.FaceEdgeVertexA:=TempFaceEdge^.Vertices[0];
     TempFaceEdgeHashItem^.FaceEdgeVertexB:=TempFaceEdge^.Vertices[1];
    end else begin
     TempFaceEdgeHashItem:=@TempFaceEdgeHashItems[TempFaceEdgeHashItemIndex];
     if (TempFaceEdgeHashItem^.Edge<0) and (TempFaceEdgeHashItem^.Face<>TempFaceEdge^.Face) then begin
      TempFaceEdgeHashItem^.Edge:=CountEdges;
      Edge:=@Edges[CountEdges];
      inc(CountEdges);
      Edge^.Vertices[0]:=TempFaceEdgeHashItem^.FaceEdgeVertexA;
      Edge^.Vertices[1]:=TempFaceEdgeHashItem^.FaceEdgeVertexB;
      Edge^.Faces[0]:=TempFaceEdgeHashItem^.Face;
      Edge^.Faces[1]:=TempFaceEdge^.Face;
     end else begin
      raise EKraftDegeneratedConvexHull.Create('Degenerated convex hull');
     end;
    end;
   end;
   for TempFaceEdgeHashItemIndex:=0 to CountTempFaceEdgeHashItems-1 do begin
    TempFaceEdgeHashItem:=@TempFaceEdgeHashItems[TempFaceEdgeHashItemIndex];
    if TempFaceEdgeHashItem^.Edge<0 then begin
     raise EKraftDegeneratedConvexHull.Create('Degenerated convex hull');
    end;
   end;
   SetLength(Edges,CountEdges);
  finally
   SetLength(TempFaceEdgeHashItems,0);
   SetLength(TempFaceEdgeHashTable,0);
  end;

 finally
  SetLength(TempPoints,0);
  SetLength(TempTriangles,0);
  SetLength(TempFaceEdges,0);
 end;
end;

procedure TKraftConvexHull.Update;
var FaceIndex,VertexIndex:longint;
    Face:PKraftConvexHullFace;
    v0,v1,v2:PKraftVector3;
begin

 for FaceIndex:=0 to CountFaces-1 do begin
  Face:=@Faces[FaceIndex];
  if Face^.CountVertices>2 then begin
   v0:=@Vertices[Face^.Vertices[0]].Position;
   v1:=@Vertices[Face^.Vertices[1]].Position;
   v2:=@Vertices[Face^.Vertices[2]].Position;
   Face^.Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(v1^,v0^),Vector3Sub(v2^,v0^)));
   Face^.Plane.Distance:=-Vector3Dot(Face^.Plane.Normal,v0^);
  end;
 end;

 Sphere.Center.x:=0.0;
 Sphere.Center.y:=0.0;
 Sphere.Center.z:=0.0;
 Sphere.Radius:=0.0;
 if CountVertices>0 then begin
  v0:=@Vertices[0].Position;
  AABB.Min:=v0^;
  AABB.Max:=v0^;
  Sphere.Center:=v0^;
  for VertexIndex:=1 to CountVertices-1 do begin
   v0:=@Vertices[VertexIndex].Position;
   if AABB.Min.x>v0^.x then begin
    AABB.Min.x:=v0^.x;
   end;
   if AABB.Min.y>v0^.y then begin
    AABB.Min.y:=v0^.y;
   end;
   if AABB.Min.z>v0^.z then begin
    AABB.Min.z:=v0^.z;
   end;
   if AABB.Max.x<v0^.x then begin
    AABB.Max.x:=v0^.x;
   end;
   if AABB.Max.y<v0^.y then begin
    AABB.Max.y:=v0^.y;
   end;
   if AABB.Max.z<v0^.z then begin
    AABB.Max.z:=v0^.z;
   end;
   Sphere.Center.x:=Sphere.Center.x+v0^.x;
   Sphere.Center.y:=Sphere.Center.y+v0^.y;
   Sphere.Center.z:=Sphere.Center.z+v0^.z;
  end;
  Sphere.Center.x:=Sphere.Center.x/CountVertices;
  Sphere.Center.y:=Sphere.Center.y/CountVertices;
  Sphere.Center.z:=Sphere.Center.z/CountVertices;
  for VertexIndex:=0 to CountVertices-1 do begin
   Sphere.Radius:=Max(Sphere.Radius,Vector3Length(Vector3Sub(Sphere.Center,Vertices[VertexIndex].Position)));
  end;
 end else begin
  AABB.Min.x:=3.4e+38;
  AABB.Min.y:=3.4e+38;
  AABB.Min.z:=3.4e+38;
  AABB.Max.x:=-3.4e+38;
  AABB.Max.y:=-3.4e+38;
  AABB.Max.z:=-3.4e+38;
 end;

 AngularMotionDisc:=Vector3Length(Sphere.Center)+Sphere.Radius;

end;

procedure TKraftConvexHull.CalculateMassData;
const ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
      Density=1.0;
 function cube(x:TKraftScalar):TKraftScalar;
 begin
  result:=x*x*x;
 end;
var i,j,k,a,b,c,v0,v1,v2:longint;
    Face:PKraftConvexHullFace;
    nx,ny,nz,Fa,Fb,Fc,Faa,Fbb,Fcc,Faaa,Fbbb,Fccc,Faab,Fbbc,Fcca,
    P1,Pa,Pb,Paa,Pab,Pbb,Paaa,Paab,Pabb,Pbbb,w,k1,k2,k3,k4,t0,
    a0,a1,da,b0,b1,db,a0_2,a0_3,a0_4,b0_2,b0_3,b0_4,
    a1_2,a1_3,b1_2,b1_3,C1,Ca,Caa,Caaa,Cb,Cbb,Cbbb,
    Cab,Kab,Caab,Kaab,Cabb,Kabb:TKraftScalar;
    vn,va,vb,t1,t2,tp:TKraftVector3;
    Transform:TKraftMatrix4x4;
begin

 // Based on Brian Mirtich, "Fast and Accurate Computation of Polyhedral Mass Properties," journal of graphics tools, volume 1, number 2, 1996.
 begin
  t0:=0.0;
  t1:=Vector3Origin;
  t2:=Vector3Origin;
  tp:=Vector3Origin;

  for i:=0 to CountFaces-1 do begin

   Face:=@Faces[i];

   for j:=1 to Face^.CountVertices-2 do begin

    v0:=Face^.Vertices[0];
    v1:=Face^.Vertices[j];
    v2:=Face^.Vertices[j+1];

    va:=Vector3Sub(Vertices[v1].Position,Vertices[v0].Position);
    vb:=Vector3Sub(Vertices[v2].Position,Vertices[v0].Position);
    vn:=Vector3Cross(vb,va);
    nx:=abs(vn.x);
    ny:=abs(vn.y);
    nz:=abs(vn.z);
    if (nx>ny) and (nx>nz) then begin
     c:=0;
    end else if ny>nx then begin
     c:=1;
    end else begin
     c:=2;
    end;

    // Even though all triangles might be initially valid,
    // a triangle may degenerate into a segment after applying
    // space transformation.
    if abs(vn.xyz[c])>EPSILON then begin
     a:=ModuloThree[c+1];
     b:=ModuloThree[a+1];

     begin
      // Calculate face integrals
      begin
       a0:=0;
       a1:=0;
       b0:=0;
       b1:=0;
       P1:=0;
       Pa:=0;
       Pb:=0;
       Paa:=0;
       Pab:=0;
       Pbb:=0;
       Paaa:=0;
       Paab:=0;
       Pabb:=0;
       Pbbb:=0;
       for k:=0 to 2 do begin
        case k of
         0:begin
          a0:=Vertices[v0].Position.xyz[a];
          b0:=Vertices[v0].Position.xyz[b];
          a1:=Vertices[v1].Position.xyz[a];
          b1:=Vertices[v1].Position.xyz[b];
         end;
         1:begin
          a0:=Vertices[v1].Position.xyz[a];
          b0:=Vertices[v1].Position.xyz[b];
          a1:=Vertices[v2].Position.xyz[a];
          b1:=Vertices[v2].Position.xyz[b];
         end;
         2:begin
          a0:=Vertices[v2].Position.xyz[a];
          b0:=Vertices[v2].Position.xyz[b];
          a1:=Vertices[v0].Position.xyz[a];
          b1:=Vertices[v0].Position.xyz[b];
         end;
        end;
        da:=a1-a0;
        db:=b1-b0;
        a0_2:=a0*a0;
        a0_3:=a0_2*a0;
        a0_4:=a0_3*a0;
        b0_2:=b0*b0;
        b0_3:=b0_2*b0;
        b0_4:=b0_3*b0;
        a1_2:=a1*a1;
        a1_3:=a1_2*a1;
        b1_2:=b1*b1;
        b1_3:=b1_2*b1;
        C1:=a1+a0;
        Ca:=(a1*C1)+a0_2;
        Caa:=(a1*Ca)+a0_3;
        Caaa:=(a1*Caa)+a0_4;
        Cb:=(b1*(b1+b0))+b0_2;
        Cbb:=(b1*Cb)+b0_3;
        Cbbb:=(b1*Cbb)+b0_4;
        Cab:=(3.0*a1_2)+(2.0*a1*a0)+a0_2;
        Kab:=a1_2+(2.0*a1*a0)+(3*a0_2);
        Caab:=(a0*Cab)+(4.0*a1_3);
        Kaab:=(a1*Kab)+(4.0*a0_3);
        Cabb:=(4.0*b1_3)+(3.0*b1_2*b0)+(2.0*b1*b0_2)+b0_3;
        Kabb:=b1_3+(2.0*b1_2*b0)+(3.0*b1*b0_2)+(4.0*b0_3);
        P1:=P1+(db*C1);
        Pa:=Pa+(db*Ca);
        Paa:=Paa+(db*Caa);
        Paaa:=Paaa+(db*Caaa);
        Pb:=Pb+(da*Cb);
        Pbb:=Pbb+(da*Cbb);
        Pbbb:=Pbbb+(da*Cbbb);
        Pab:=Pab+(db*((b1*Cab)+(b0*Kab)));
        Paab:=Paab+(db*((b1*Caab)+(b0*Kaab)));
        Pabb:=Pabb+(da*((a1*Cabb)+(a0*Kabb)));
       end;
       P1:=P1/2.0;
       Pa:=Pa/6.0;
       Paa:=Paa/12.0;
       Paaa:=Paaa/20.0;
       Pb:=Pb/(-6.0);
       Pbb:=Pbb/(-12.0);
       Pbbb:=Pbbb/(-20.0);
       Pab:=Pab/24.0;
       Paab:=Paab/60.0;
       Pabb:=Pabb/(-60.0);
      end;
      w:=-Vector3Dot(vn,Vertices[v0].Position);
      k1:=1.0/vn.xyz[c];
      k2:=k1*k1;
      k3:=k2*k1;
      k4:=k3*k1;
      Fa:=k1*Pa;
      Fb:=k1*Pb;
      Fc:=(-k2)*((vn.xyz[A]*Pa)+(vn.xyz[B]*Pb)+(w*P1));
      Faa:=k1*Paa;
      Fbb:=k1*Pbb;
      Fcc:=k3*((sqr(vn.xyz[A])*Paa)+(2.0*vn.xyz[A]*vn.xyz[B]*Pab)+(sqr(vn.xyz[B])*Pbb)+(w*(2.0*((vn.xyz[A]*Pa)+(vn.xyz[B]*Pb))+(w*P1))));
      Faaa:=k1*Paaa;
      Fbbb:=k1*Pbbb;
      Fccc:=(-k4)*((CUBE(vn.xyz[A])*Paaa)+(3.0*sqr(vn.xyz[A])*vn.xyz[B]*Paab)+(3.0*vn.xyz[A]*sqr(vn.xyz[B])*Pabb)+(CUBE(vn.xyz[B])*Pbbb)+
            (3.0*w*((sqr(vn.xyz[A])*Paa)+(2.0*vn.xyz[A]*vn.xyz[B]*Pab)+(sqr(vn.xyz[B])*Pbb)))+
            (w*w*(3.0*((vn.xyz[A]*Pa)+(vn.xyz[B]*Pb))+(w*P1))));
      Faab:=k1*Paab;
      Fbbc:=(-k2)*((vn.xyz[A]*Pabb)+(vn.xyz[B]*Pbbb)+(w*Pbb));
      Fcca:=k3*((sqr(vn.xyz[A])*Paaa)+(2.0*vn.xyz[A]*vn.xyz[B]*Paab)+(sqr(vn.xyz[B])*Pabb)+(w*(2.0*((vn.xyz[A]*Paa)+(vn.xyz[B]*Pab))+(w*Pa))));
     end;
     if a=0 then begin
      t0:=t0+(vn.x*Fa);
     end else if b=0 then begin
      t0:=t0+(vn.x*Fb);
     end else begin
      t0:=t0+(vn.x*Fc);
     end;
     T1.xyz[A]:=T1.xyz[A]+(vn.xyz[A]*Faa);
     T1.xyz[B]:=T1.xyz[B]+(vn.xyz[B]*Fbb);
     T1.xyz[C]:=T1.xyz[C]+(vn.xyz[C]*Fcc);
     T2.xyz[A]:=T2.xyz[A]+(vn.xyz[A]*Faaa);
     T2.xyz[B]:=T2.xyz[B]+(vn.xyz[B]*Fbbb);
     T2.xyz[C]:=T2.xyz[C]+(vn.xyz[C]*Fccc);
     TP.xyz[A]:=TP.xyz[A]+(vn.xyz[A]*Faab);
     TP.xyz[B]:=TP.xyz[B]+(vn.xyz[B]*Fbbc);
     TP.xyz[C]:=TP.xyz[C]+(vn.xyz[C]*Fcca);
    end;
   end;
  end;
  Vector3Scale(T1,1.0/2.0);
  Vector3Scale(T2,1.0/3.0);
  Vector3Scale(TP,1.0/2.0);
  MassData.Volume:=t0;
  MassData.Mass:=t0*Density;
  MassData.Inertia[0,0]:=Density*(t2.y+t2.z);
  MassData.Inertia[0,1]:=-(Density*tp.x);
  MassData.Inertia[0,2]:=-(Density*tp.z);
  MassData.Inertia[1,0]:=-(Density*tp.x);
  MassData.Inertia[1,1]:=Density*(t2.z+t2.x);
  MassData.Inertia[1,2]:=-(Density*tp.y);
  MassData.Inertia[2,0]:=-(Density*tp.z);
  MassData.Inertia[2,1]:=-(Density*tp.y);
  MassData.Inertia[2,2]:=Density*(t2.x+t2.y);
  MassData.Center:=Vector3ScalarMul(T1,1.0/t0);
//MassData.Translate(Vector3ScalarMul(T1,1.0/t0));
 end;

end;

procedure TKraftConvexHull.CalculateCentroid;
var i,j:longint;
    Face:PKraftConvexHullFace;
    vA,vB,vC:PKraftVector3;
    x,y,z,Volume,Denominator:double;
    AreaMagnitudeNormal:TKraftVector3;
begin

 x:=0.0;
 y:=0.0;
 z:=0.0;
 Volume:=0.0;

 for i:=0 to CountFaces-1 do begin

  Face:=@Faces[i];

  vA:=@Vertices[Face^.Vertices[0]].Position;

  for j:=1 to Face^.CountVertices-2 do begin

   vB:=@Vertices[Face^.Vertices[j]].Position;

   vC:=@Vertices[Face^.Vertices[j+1]].Position;

   // Compute area-magnitude normal
   AreaMagnitudeNormal:=Vector3Cross(Vector3Sub(vB^,vA^),Vector3Sub(vC^,vA^));

   // Compute contribution to volume integral
   Volume:=Volume+Vector3Dot(vA^,AreaMagnitudeNormal);

   // Compute contribution to centroid integral for each dimension
   x:=x+((sqr(vA^.x+vB^.x)+sqr(vB^.x+vC^.x)+sqr(vC^.x+vA^.x))*AreaMagnitudeNormal.x);
   y:=y+((sqr(vA^.y+vB^.y)+sqr(vB^.y+vC^.y)+sqr(vC^.y+vA^.y))*AreaMagnitudeNormal.y);
   z:=z+((sqr(vA^.z+vB^.z)+sqr(vB^.z+vC^.z)+sqr(vC^.z+vA^.z))*AreaMagnitudeNormal.z);

  end;

 end;

 Denominator:=Volume*8.0; // 8.0 = 48.0/6.0 = (24.0*2.0)/6.0

 Centroid.x:=x/Denominator;
 Centroid.y:=y/Denominator;
 Centroid.z:=z/Denominator;

end;

procedure TKraftConvexHull.Finish;
const Steps=1024;
      ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
var VertexIndex:longint;
    v:PKraftVector3;
begin

 SetLength(Vertices,CountVertices);

 CalculateMassData;

 CalculateCentroid;

 // Construct AABB and bounding sphere
 Sphere.Center.x:=0.0;
 Sphere.Center.y:=0.0;
 Sphere.Center.z:=0.0;
 Sphere.Radius:=0.0;
 if CountVertices>0 then begin
  v:=@Vertices[0].Position;
  AABB.Min:=v^;
  AABB.Max:=v^;
  Sphere.Center:=v^;
  for VertexIndex:=1 to CountVertices-1 do begin
   v:=@Vertices[VertexIndex].Position;
   if AABB.Min.x>v^.x then begin
    AABB.Min.x:=v^.x;
   end;
   if AABB.Min.y>v^.y then begin
    AABB.Min.y:=v^.y;
   end;
   if AABB.Min.z>v^.z then begin
    AABB.Min.z:=v^.z;
   end;
   if AABB.Max.x<v^.x then begin
    AABB.Max.x:=v^.x;
   end;
   if AABB.Max.y<v^.y then begin
    AABB.Max.y:=v^.y;
   end;
   if AABB.Max.z<v^.z then begin
    AABB.Max.z:=v^.z;
   end;
   Sphere.Center.x:=Sphere.Center.x+v^.x;
   Sphere.Center.y:=Sphere.Center.y+v^.y;
   Sphere.Center.z:=Sphere.Center.z+v^.z;
  end;
  Sphere.Center.x:=Sphere.Center.x/CountVertices;
  Sphere.Center.y:=Sphere.Center.y/CountVertices;
  Sphere.Center.z:=Sphere.Center.z/CountVertices;
  for VertexIndex:=0 to CountVertices-1 do begin
   Sphere.Radius:=Max(Sphere.Radius,Vector3Length(Vector3Sub(Sphere.Center,Vertices[VertexIndex].Position)));
  end;
 end else begin
  AABB.Min.x:=3.4e+38;
  AABB.Min.y:=3.4e+38;
  AABB.Min.z:=3.4e+38;
  AABB.Max.x:=-3.4e+38;
  AABB.Max.y:=-3.4e+38;
  AABB.Max.z:=-3.4e+38;
 end;

 AngularMotionDisc:=Vector3Length(Sphere.Center)+Sphere.Radius;

end;

function TKraftConvexHull.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 if (Index>=0) and (Index<CountVertices) then begin
  result:=Vertices[Index].Position;
 end else begin
  result:=MassData.Center; //Vector3Origin;
 end;
end;

function TKraftConvexHull.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
var Normal:TKraftVector3;
    Index,BestVertexIndex,NewVertexIndex,CurrentVertexIndex:longint;
    BestDistance,NewDistance,CurrentDistance:TKraftScalar;
    Vertex,CurrentVertex:PKraftConvexHullVertex;
begin
 if CountVertices>0 then begin
  Normal:=Vector3SafeNorm(Direction);
  BestVertexIndex:=0;
  BestDistance:=Vector3Dot(Vertices[BestVertexIndex].Position,Normal);
  if CountVertices<32 then begin
   for Index:=1 to CountVertices-1 do begin
    CurrentDistance:=Vector3Dot(Vertices[Index].Position,Normal);
    if BestDistance<CurrentDistance then begin
     BestDistance:=CurrentDistance;
     BestVertexIndex:=Index;
    end;
   end;
  end else begin
   repeat
    NewVertexIndex:=BestVertexIndex;
    NewDistance:=BestDistance;
    Vertex:=@Vertices[BestVertexIndex];
    for Index:=0 to Vertex^.CountAdjacencies-1 do begin
     CurrentVertexIndex:=Vertex^.Adjacencies[Index];
     CurrentVertex:=@Vertices[CurrentVertexIndex];
     CurrentDistance:=Vector3Dot(CurrentVertex^.Position,Normal);
     if NewDistance<CurrentDistance then begin
      NewVertexIndex:=CurrentVertexIndex;
      NewDistance:=CurrentDistance;
     end;
    end;
    if NewVertexIndex=BestVertexIndex then begin
     break;
    end;
    BestVertexIndex:=NewVertexIndex;
    BestDistance:=NewDistance;
   until false;
  end;
  result:=BestVertexIndex;
 end else begin
  result:=-1;
 end;
end;

function TKraftConvexHull.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
var Normal:TKraftVector3;
    Index,BestVertexIndex,NewVertexIndex,CurrentVertexIndex:longint;
    BestDistance,NewDistance,CurrentDistance:TKraftScalar;
    Vertex,CurrentVertex:PKraftConvexHullVertex;
begin
 if CountVertices>0 then begin
  Normal:=Vector3SafeNorm(Direction);
  BestVertexIndex:=0;
  BestDistance:=Vector3Dot(Vertices[BestVertexIndex].Position,Normal);
  if CountVertices<32 then begin
   for Index:=1 to CountVertices-1 do begin
    CurrentDistance:=Vector3Dot(Vertices[Index].Position,Normal);
    if BestDistance<CurrentDistance then begin
     BestDistance:=CurrentDistance;
     BestVertexIndex:=Index;
    end;
   end;
  end else begin
   repeat
    NewVertexIndex:=BestVertexIndex;
    NewDistance:=BestDistance;
    Vertex:=@Vertices[BestVertexIndex];
    for Index:=0 to Vertex^.CountAdjacencies-1 do begin
     CurrentVertexIndex:=Vertex^.Adjacencies[Index];
     CurrentVertex:=@Vertices[CurrentVertexIndex];
     CurrentDistance:=Vector3Dot(CurrentVertex^.Position,Normal);
     if NewDistance<CurrentDistance then begin
      NewVertexIndex:=CurrentVertexIndex;
      NewDistance:=CurrentDistance;
     end;
    end;
    if NewVertexIndex=BestVertexIndex then begin
     break;
    end;
    BestVertexIndex:=NewVertexIndex;
    BestDistance:=NewDistance;
   until false;
  end;
  result:=Vertices[BestVertexIndex].Position;
 end else begin
  result:=MassData.Center;
 end;
end;

constructor TKraftMesh.Create(const APhysics:TKraft);
begin

 inherited Create;

 Physics:=APhysics;

 Vertices:=nil;
 CountVertices:=0;

 Normals:=nil;
 CountNormals:=0;

 Triangles:=nil;
 CountTriangles:=0;

 SkipListNodes:=nil;
 CountSkipListNodes:=0;

 if assigned(Physics.MeshLast) then begin
  Physics.MeshLast.Next:=self;
  Previous:=Physics.MeshLast;
 end else begin
  Physics.MeshFirst:=self;
  Previous:=nil;
 end;
 Physics.MeshLast:=self;
 Next:=nil;

end;

destructor TKraftMesh.Destroy;
begin

 SetLength(Vertices,0);

 SetLength(Normals,0);

 SetLength(Triangles,0);

 SetLength(SkipListNodes,0);

 if assigned(Previous) then begin
  Previous.Next:=Next;
 end else if Physics.MeshFirst=self then begin
  Physics.MeshFirst:=Next;
 end;
 if assigned(Next) then begin
  Next.Previous:=Previous;
 end else if Physics.MeshLast=self then begin
  Physics.MeshLast:=Previous;
 end;
 Previous:=nil;
 Next:=nil;

 inherited Destroy;

end;

function TKraftMesh.AddVertex(const AVertex:TKraftVector3):longint;
begin
 result:=CountVertices;
 inc(CountVertices);
 if CountVertices>length(Vertices) then begin
  SetLength(Vertices,CountVertices*2);
 end;
 Vertices[result]:=AVertex;
end;

function TKraftMesh.AddNormal(const ANormal:TKraftVector3):longint;
begin
 result:=CountNormals;
 inc(CountNormals);
 if CountNormals>length(Normals) then begin
  SetLength(Normals,CountNormals*2);
 end;
 Normals[result]:=ANormal;
end;

function TKraftMesh.AddTriangle(const AVertexIndex0,AVertexIndex1,AVertexIndex2:longint;const ANormalIndex0:longint=-1;const ANormalIndex1:longint=-1;ANormalIndex2:longint=-1):longint;
var Triangle:PKraftMeshTriangle;
begin
 result:=CountTriangles;
 inc(CountTriangles);
 if CountTriangles>length(Triangles) then begin
  SetLength(Triangles,CountTriangles*2);
 end;
 Triangle:=@Triangles[result];
 Triangle^.Vertices[0]:=AVertexIndex0;
 Triangle^.Vertices[1]:=AVertexIndex1;
 Triangle^.Vertices[2]:=AVertexIndex2;
 Triangle^.Normals[0]:=ANormalIndex0;
 Triangle^.Normals[1]:=ANormalIndex1;
 Triangle^.Normals[2]:=ANormalIndex2;
 Triangle^.Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[Triangle^.Vertices[1]],Vertices[Triangle^.Vertices[0]]),Vector3Sub(Vertices[Triangle^.Vertices[2]],Vertices[Triangle^.Vertices[0]])));
 Triangle^.Plane.Distance:=-Vector3Dot(Triangle^.Plane.Normal,Vertices[Triangle^.Vertices[0]]);
 Triangle^.Next:=-1;
end;

procedure TKraftMesh.Load(const AVertices:PKraftVector3;const ACountVertices:longint;const ANormals:PKraftVector3;const ACountNormals:longint;const AVertexIndices,ANormalIndices:pointer;const ACountIndices:longint);
var i:longint;
    Triangle:PKraftMeshTriangle;
    v,n:plongint;
    HasNormals:boolean;
begin

 HasNormals:=assigned(ANormals) and (ACountNormals>0) and assigned(ANormalIndices);

 Vertices:=nil;
 CountVertices:=ACountVertices;
 SetLength(Vertices,CountVertices);
 for i:=0 to CountVertices-1 do begin
  Vertices[i]:=PKraftVector3s(AVertices)^[i];
 end;

 Normals:=nil;
 if HasNormals then begin
  CountNormals:=ACountNormals;
  SetLength(Normals,CountNormals);
  for i:=0 to CountNormals-1 do begin
   Normals[i]:=PKraftVector3s(ANormals)^[i];
  end;
 end else begin
  CountNormals:=0;
 end;

 Triangles:=nil;
 CountTriangles:=ACountIndices div 3;
 SetLength(Triangles,CountTriangles);
 v:=AVertexIndices;
 n:=ANormalIndices;
 for i:=0 to CountTriangles-1 do begin
  Triangle:=@Triangles[i];
  Triangle^.Vertices[0]:=v^;
  inc(v);
  Triangle^.Vertices[1]:=v^;
  inc(v);
  Triangle^.Vertices[2]:=v^;
  inc(v);
  if HasNormals then begin
   Triangle^.Normals[0]:=n^;
   inc(n);
   Triangle^.Normals[1]:=n^;
   inc(n);
   Triangle^.Normals[2]:=n^;
   inc(n);
  end else begin
   Triangle^.Normals[0]:=-1;
   Triangle^.Normals[1]:=-1;
   Triangle^.Normals[2]:=-1;
  end;
  Triangle^.Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[Triangle^.Vertices[1]],Vertices[Triangle^.Vertices[0]]),Vector3Sub(Vertices[Triangle^.Vertices[2]],Vertices[Triangle^.Vertices[0]])));
  Triangle^.Plane.Distance:=-Vector3Dot(Triangle^.Plane.Normal,Vertices[Triangle^.Vertices[0]]);
  Triangle^.Next:=-1;
 end;

end;

procedure TKraftMesh.Load(const ASourceData:pointer;const ASourceSize:longint);
type TFileSignature=array[0..3] of ansichar;
var SrcPos:longint;
    Signature:TFileSignature;
 function Read(var Dst;DstLen:longword):longword;
 begin
  result:=ASourceSize-SrcPos;
  if result>DstLen then begin
   result:=DstLen;
  end;
  if result>0 then begin
   Move(PAnsiChar(ASourceData)[SrcPos],Dst,result);
   inc(SrcPos,result);
  end;
 end;
 function ReadByte:byte;
 begin
  Read(result,SizeOf(byte));
 end;
 function ReadWord:word;
 begin
  Read(result,SizeOf(word));
 end;
 function ReadLongWord:longword;
 begin
  Read(result,SizeOf(longword));
 end;
 function ReadFloat:single;
 begin
  Read(result,SizeOf(single));
 end;
 procedure LoadPMF;
 type TFace=record
       Indices:array[0..2] of longword;
      end;
      PFaces=^TFaces;
      TFaces=array[0..0] of TFace;
 var Counter:longint;
     Triangle:PKraftMeshTriangle;
 begin
  CountTriangles:=ReadLongWord;
  SetLength(Triangles,CountTriangles);
  CountVertices:=ReadLongWord;
  if (CountTriangles>0) and (CountVertices>0) then begin
   for Counter:=0 to CountTriangles-1 do begin
    Triangle:=@Triangles[Counter];
    Triangle^.Vertices[0]:=ReadLongWord;
    Triangle^.Vertices[1]:=ReadLongWord;
    Triangle^.Vertices[2]:=ReadLongWord;
    Triangle^.Normals[0]:=-1;
    Triangle^.Normals[1]:=-1;
    Triangle^.Normals[2]:=-1;
   end;
   SetLength(Vertices,CountVertices);
   for Counter:=0 to CountVertices-1 do begin
    Vertices[Counter].x:=ReadFloat;
    Vertices[Counter].y:=ReadFloat;
    Vertices[Counter].z:=ReadFloat;
   end;
   for Counter:=0 to CountTriangles-1 do begin
    Triangle:=@Triangles[Counter];
    Triangle^.Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[Triangle^.Vertices[1]],Vertices[Triangle^.Vertices[0]]),Vector3Sub(Vertices[Triangle^.Vertices[2]],Vertices[Triangle^.Vertices[0]])));
    Triangle^.Plane.Distance:=-Vector3Dot(Triangle^.Plane.Normal,Vertices[Triangle^.Vertices[0]]);
    Triangle^.Next:=-1;
   end;
  end;
 end;
 function Load3DS(SrcData:pointer;SrcSize:longword):boolean;
 const CHUNK_3DS_MAIN=$4d4d;
       CHUNK_3DS_OBJMESH=$3d3d;
       CHUNK_3DS_OBJBLOCK=$4000;
       CHUNK_3DS_TRIMESH=$4100;
       CHUNK_3DS_VERTLIST=$4110;
       CHUNK_3DS_FACELIST=$4120;
       CHUNK_3DS_MAPLIST=$4140;
       CHUNK_3DS_SMOOTHLIST=$4150;
       CHUNK_3DS_MESHMATRIX=$4160;
 type PVector2=^TVector2;
      TVector2=TKraftVector2;
      PVector2Array=^TVector2Array;
      TVector2Array=array[0..0] of TVector2;
      PVector3Array=^TKraftVector3Array;
      TKraftVector3Array=array[0..0] of TKraftVector3;
      PFace3DS=^TFace3DS;
      TFace3DS=record
       Indices:array[0..2] of longword;
       Flags:longword;
       SmoothGroup:longword;
      end;
      PFaces3DS=^TFaces3DS;
      TFaces3DS=array[0..0] of TFace3DS;
      PObject3DSMesh=^TObject3DSMesh;
      TObject3DSMesh=record
       Vertices:PVector3Array;
       NumVertices:longint;
       TexCoords:PVector2Array;
       NumTexCoords:longint;
       Faces:PFaces3DS;
       NumFaces:longint;
       Matrix:TKraftMatrix4x4;
      end;
      PObject3DSMeshs=^TObject3DSMeshs;
      TObject3DSMeshs=array[0..0] of TObject3DSMesh;
      PObject3DS=^TObject3DS;
      TObject3DS=record
       Name:PAnsiChar;
       Meshs:PObject3DSMeshs;
       NumMeshs:longint;
      end;
      PObjects3DS=^TObjects3DS;
      TObjects3DS=array[0..0] of TObject3DS;
 var SrcPos:longword;
     Signature3DS:word;
     Size3DS:longword;
     Objects3DS:PObjects3DS;
     NumObjects3DS:longint;
  function Read(var Dst;DstLen:longword):longword;
  begin
   result:=SrcSize-SrcPos;
   if result>DstLen then begin
    result:=DstLen;
   end;
   if result>0 then begin
    Move(PAnsiChar(SrcData)[SrcPos],Dst,result);
    inc(SrcPos,result);
   end;
  end;
  function ReadByte:byte;
  begin
   Read(result,SizeOf(byte));
  end;
  function ReadWord:word;
  begin
   Read(result,SizeOf(word));
  end;
  function ReadLongWord:longword;
  begin
   Read(result,SizeOf(longword));
  end;
  function ReadFloat:single;
  begin
   Read(result,SizeOf(single));
  end;
  procedure ReallocateMemory(var p;Size:longint);
  begin
   if assigned(pointer(p)) then begin
    if Size=0 then begin
     FreeMem(pointer(p));
     pointer(p):=nil;
    end else begin
     ReallocMem(pointer(p),Size);
    end;
   end else if Size<>0 then begin
    GetMem(pointer(p),Size);
   end;
  end;
  function Read3DSChunks(const ParentChunk,Bytes:longword):longword; forward;
  function Skip3DSString:longword;
  var c:ansichar;
  begin
   result:=0;
   c:=#255;
   while c<>#0 do begin
    if Read(c,SizeOf(ansichar))<>SizeOf(ansichar) then begin
     break;
    end;
    inc(result);
   end;
  end;
  function Read3DSString(var p:PAnsiChar):longword;
  var c:ansichar;
      OldPos:longword;
  begin
   OldPos:=SrcPos;
   result:=0;
   c:=#255;
   while c<>#0 do begin
    if Read(c,SizeOf(ansichar))<>SizeOf(ansichar) then begin
     break;
    end;
    inc(result);
   end;
   GetMem(p,result);
   SrcPos:=OldPos;
   result:=0;
   c:=#255;
   while c<>#0 do begin
    if Read(c,SizeOf(ansichar))<>SizeOf(ansichar) then begin
     break;
    end;
    p[result]:=c;
    inc(result);
   end;
  end;
  function Read3DSChunk(const ParentChunk:longword):longword;
  var Chunk:word;
      Size,i,j:longword;
      Vertex:PKraftVector3;
      TexCoord:PVector2;
      Face:PFace3DS;
  begin
   if Read(Chunk,SizeOf(word))<>SizeOf(word) then begin
    result:=$80000000;
    exit;
   end;
   if Read(result,SizeOf(longword))<>SizeOf(longword) then begin
    result:=$80000000;
    exit;
   end;
   Size:=result-6;
   case ParentChunk of
    CHUNK_3DS_MAIN:begin
     case Chunk of
      CHUNK_3DS_OBJMESH:begin
       Read3DSChunks(Chunk,Size);
      end;
      else begin
       inc(SrcPos,Size);
      end;
     end;
    end;
    CHUNK_3DS_OBJMESH:begin
     case Chunk of
      CHUNK_3DS_OBJBLOCK:begin
       inc(NumObjects3DS);
       ReallocateMemory(Objects3DS,NumObjects3DS*SizeOf(TObject3DS));
       FillChar(Objects3DS^[NumObjects3DS-1],SizeOf(TObject3DS),#0);
       dec(Size,Read3DSString(Objects3DS^[NumObjects3DS-1].Name));
       Read3DSChunks(Chunk,Size);
      end;
      else begin
       inc(SrcPos,Size);
      end;
     end;
    end;
    CHUNK_3DS_OBJBLOCK:begin
     case Chunk of
      CHUNK_3DS_TRIMESH:begin
       inc(Objects3DS^[NumObjects3DS-1].NumMeshs);
       ReallocateMemory(Objects3DS^[NumObjects3DS-1].Meshs,Objects3DS^[NumObjects3DS-1].NumMeshs*SizeOf(TObject3DSMesh));
       FillChar(Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1],SizeOf(TObject3DSMesh),#0);
       Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Matrix:=Matrix4x4Identity;
       Read3DSChunks(Chunk,Size);
      end;
      else begin
       inc(SrcPos,Size);
      end;
     end;
    end;
    CHUNK_3DS_TRIMESH:begin
     case Chunk of
      CHUNK_3DS_VERTLIST:begin
       Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumVertices:=ReadWord;
       ReallocateMemory(Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Vertices,Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumVertices*SizeOf(TKraftVector3));
       Vertex:=@Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Vertices^[0];
       for i:=1 to Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumVertices do begin
        Vertex^.x:=ReadFloat;
        Vertex^.y:=ReadFloat;
        Vertex^.z:=ReadFloat;
        inc(Vertex);
       end;
      end;
      CHUNK_3DS_MAPLIST:begin
       Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumTexCoords:=ReadWord;
       ReallocateMemory(Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].TexCoords,Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumTexCoords*SizeOf(TVector2));
       TexCoord:=@Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].TexCoords^[0];
       for i:=1 to Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumTexCoords do begin
        TexCoord^.x:=ReadFloat;
        TexCoord^.y:=ReadFloat;
        inc(TexCoord);
       end;
      end;
      CHUNK_3DS_FACELIST:begin
       Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumFaces:=ReadWord;
       ReallocateMemory(Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Faces,Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumFaces*SizeOf(TFace3DS));
       Face:=@Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Faces^[0];
       for i:=1 to Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumFaces do begin
        Face^.Indices[0]:=ReadWord;
        Face^.Indices[1]:=ReadWord;
        Face^.Indices[2]:=ReadWord;
        Face^.Flags:=ReadWord;
        inc(Face);
       end;
       dec(Size,(Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumFaces*4)+2);
       Read3DSChunks(Chunk,Size);
      end;
      CHUNK_3DS_MESHMATRIX:begin
       Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Matrix:=Matrix4x4Identity;
       for i:=0 to 3 do begin
        for j:=0 to 2 do begin
         Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Matrix[i,j]:=ReadFloat;
        end;
       end;
      end;
      else begin
       inc(SrcPos,Size);
      end;
     end;
    end;
    CHUNK_3DS_FACELIST:begin
     case Chunk of
      CHUNK_3DS_SMOOTHLIST:begin
       Face:=@Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].Faces^[0];
       for i:=1 to Objects3DS^[NumObjects3DS-1].Meshs^[Objects3DS^[NumObjects3DS-1].NumMeshs-1].NumFaces do begin
        Face^.SmoothGroup:=ReadLongWord;
        inc(Face);
       end;
      end;
      else begin
       inc(SrcPos,Size);
      end;
     end;
    end;
    else begin
     inc(SrcPos,Size);
    end;
   end;
  end;
  function Read3DSChunks(const ParentChunk,Bytes:longword):longword;
  begin
   result:=0;
   while result<Bytes do begin
    inc(result,Read3DSChunk(ParentChunk));
   end;
  end;
  procedure Convert3DS;
  var i,j,k,h:longint;
      v:array[0..2] of TKraftVector3;
      tv:TKraftVector3;
  begin
   for i:=0 to NumObjects3DS-1 do begin
    for j:=0 to Objects3DS^[i].NumMeshs-1 do begin
     for k:=0 to Objects3DS^[i].Meshs^[j].NumFaces-1 do begin
      for h:=0 to 2 do begin
       tv:=Objects3DS^[i].Meshs^[j].Vertices^[Objects3DS^[i].Meshs^[j].Faces^[k].Indices[h]];
       //Vector3MatrixMul(tv,Objects3DS^[i].Meshs^[j].Matrix);
       v[h].x:=tv.x;
       v[h].y:=tv.z;
       v[h].z:=-tv.y;
      end;
      AddTriangle(AddVertex(v[0]),AddVertex(v[1]),AddVertex(v[2]));
     end;
    end;
   end;
  end;
  procedure Free3DS;
  var i,j:longint;
  begin
   for i:=0 to NumObjects3DS-1 do begin
    for j:=0 to Objects3DS^[i].NumMeshs-1 do begin
     ReallocateMemory(Objects3DS^[i].Meshs^[j].Vertices,0);
     ReallocateMemory(Objects3DS^[i].Meshs^[j].TexCoords,0);
     ReallocateMemory(Objects3DS^[i].Meshs^[j].Faces,0);
    end;
    ReallocateMemory(Objects3DS^[i].Meshs,0);
   end;
   ReallocateMemory(Objects3DS,0);
  end;
 begin
  result:=false;
  if SrcSize>0 then begin
   SrcPos:=0;
   if Read(Signature3DS,SizeOf(word))=SizeOf(word) then begin
    if Signature3DS=CHUNK_3DS_MAIN then begin
     if Read(Size3DS,SizeOf(longword))=SizeOf(longword) then begin
      Objects3DS:=nil;
      NumObjects3DS:=0;
      result:=Read3DSChunks(Signature3DS,Size3DS)>0;
      if assigned(Objects3DS) then begin
       if result then begin
        Convert3DS;
       end;
       Free3DS;
      end;
     end;
    end;
   end;
  end;
 end;
var OK:longbool;
begin
 OK:=false;
 if ASourceSize>SizeOf(TFileSignature) then begin
  SrcPos:=0;
  if Read(Signature,SizeOf(TFileSignature))=SizeOf(TFileSignature) then begin
   if (Signature[0]='P') and (Signature[1]='M') and (Signature[2]='F') and (Signature[3]='0') then begin
    LoadPMF;
    OK:=true;
   end;
  end;
  if not OK then begin
   if Load3DS(ASourceData,ASourceSize) then begin
    OK:=true;
   end;
  end;
 end;
 if not OK then begin
  raise EKraftCorruptMeshData.Create('Corrupt mesh data');
 end;
end;

procedure TKraftMesh.Scale(const WithFactor:TKraftScalar);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3Scale(Vertices[Index],WithFactor);
 end;
end;

procedure TKraftMesh.Scale(const WithVector:TKraftVector3);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3Scale(Vertices[Index],WithVector.x,WithVector.y,WithVector.z);
 end;
end;

procedure TKraftMesh.Transform(const WithMatrix:TKraftMatrix3x3);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3MatrixMul(Vertices[Index],WithMatrix);
 end;
end;

procedure TKraftMesh.Transform(const WithMatrix:TKraftMatrix4x4);
var Index:longint;
begin
 for Index:=0 to CountVertices-1 do begin
  Vector3MatrixMul(Vertices[Index],WithMatrix);
 end;
end;

procedure TKraftMesh.CalculateNormals;
var TriangleIndex,NormalIndex,Counter:longint;
    NormalCounts:array of longint;
    Triangle:PKraftMeshTriangle;
begin
 NormalCounts:=nil;
 try
  if CountTriangles>0 then begin
   CountNormals:=CountVertices;
   SetLength(NormalCounts,CountNormals);
   SetLength(Normals,CountNormals);
   for NormalIndex:=0 to CountNormals-1 do begin
    NormalCounts[NormalIndex]:=0;
    Normals[NormalIndex]:=Vector3Origin;
   end;
   for TriangleIndex:=0 to CountTriangles-1 do begin
    Triangle:=@Triangles[TriangleIndex];
    Triangle^.Normals[0]:=Triangle^.Vertices[0];
    Triangle^.Normals[1]:=Triangle^.Vertices[1];
    Triangle^.Normals[2]:=Triangle^.Vertices[2];
    Triangle^.Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices[Triangle^.Vertices[1]],Vertices[Triangle^.Vertices[0]]),Vector3Sub(Vertices[Triangle^.Vertices[2]],Vertices[Triangle^.Vertices[0]])));
    Triangle^.Plane.Distance:=-Vector3Dot(Triangle^.Plane.Normal,Vertices[Triangle^.Vertices[0]]);
    for Counter:=0 to 2 do begin
     NormalIndex:=Triangle^.Normals[Counter];
     inc(NormalCounts[NormalIndex]);
     Vector3DirectAdd(Normals[NormalIndex],Triangle^.Plane.Normal);
    end;
   end;
   for NormalIndex:=0 to CountNormals-1 do begin
    Vector3Normalize(Normals[NormalIndex]);
   end;
  end;
 finally
  SetLength(NormalCounts,0);
 end;
end;

procedure TKraftMesh.Finish;
type PAABBTreeNode=^TAABBTreeNode;
     TAABBTreeNode=record
      AABB:TKraftAABB;
      Children:array[0..1] of longint;
      TriangleIndex:longint;
     end;
     TAABBTreeNodes=array of TAABBTreeNode;
var Counter,StackPointer,CurrentNodeIndex,LeftCount,RightCount,ParentCount,AxisCounter,Axis,BestAxis,TriangleIndex,
    Balance,BestBalance,NextTriangleIndex,LeftNodeIndex,RightNodeIndex,TargetNodeIndex,Count,Root,CountNodes,Index,
    NodeID,Pass,NewStackCapacity:longint;
    Stack:array of longint;
    Points:array[0..2] of array of TKraftScalar;
    Center,Median:TKraftVector3;
    LeftAABB,RightAABB:TKraftAABB;
    Nodes:TAABBTreeNodes;
    Node:PAABBTreeNode;
    SkipListNode:PKraftMeshSkipListNode;
    Triangle:PKraftMeshTriangle;
    TriangleAABBs:array of TKraftAABB;
    CurrentAABB:PKraftAABB;
    v0,v1,v2:PKraftVector3;
begin
 if length(Vertices)<>CountVertices then begin
  SetLength(Vertices,CountVertices);
 end;
 if length(Triangles)<>CountTriangles then begin
  SetLength(Triangles,CountTriangles);
 end;
 for Index:=0 to CountTriangles-1 do begin
  Triangle:=@Triangles[Index];
  if (Triangle^.Normals[0]<0) or (Triangle^.Normals[1]<0) or (Triangle^.Normals[2]<0) then begin
   CalculateNormals;
   break;
  end;
 end;
 if CountSkipListNodes=0 then begin
  if CountTriangles>0 then begin
   Stack:=nil;
   Nodes:=nil;
   Points[0]:=nil;
   Points[1]:=nil;
   Points[2]:=nil;
   TriangleAABBs:=nil;
   try
    SetLength(TriangleAABBs,CountTriangles);
    for Index:=0 to CountTriangles-1 do begin
     Triangle:=@Triangles[Index];
     v0:=@Vertices[Triangle^.Vertices[0]];
     v1:=@Vertices[Triangle^.Vertices[1]];
     v2:=@Vertices[Triangle^.Vertices[2]];
     CurrentAABB:=@TriangleAABBs[Index];
     CurrentAABB^.Min.x:=Min(Min(v0^.x,v1^.x),v2^.x)-EPSILON;
     CurrentAABB^.Min.y:=Min(Min(v0^.y,v1^.y),v2^.y)-EPSILON;
     CurrentAABB^.Min.z:=Min(Min(v0^.z,v1^.z),v2^.z)-EPSILON;
     CurrentAABB^.Max.x:=Max(Max(v0^.x,v1^.x),v2^.x)+EPSILON;
     CurrentAABB^.Max.y:=Max(Max(v0^.y,v1^.y),v2^.y)+EPSILON;
     CurrentAABB^.Max.z:=Max(Max(v0^.z,v1^.z),v2^.z)+EPSILON;
     Triangle^.AABB:=TriangleAABBs[Index];
    end;
    Root:=0;
    CountNodes:=1;
    SetLength(Nodes,Max(CountNodes,CountTriangles));
    SetLength(Points[0],CountTriangles*6);
    SetLength(Points[1],CountTriangles*6);
    SetLength(Points[2],CountTriangles*6);
    Nodes[0].AABB:=TriangleAABBs[0];
    for Counter:=1 to CountTriangles-1 do begin
     Nodes[0].AABB:=AABBCombine(Nodes[0].AABB,TriangleAABBs[Counter]);
    end;
    for Counter:=0 to CountTriangles-2 do begin
     Triangles[Counter].Next:=Counter+1;
    end;
    Triangles[CountTriangles-1].Next:=-1;
    Nodes[0].TriangleIndex:=0;
    Nodes[0].Children[0]:=-1;
    Nodes[0].Children[1]:=-1;
    SetLength(Stack,16);
    Stack[0]:=0;
    StackPointer:=1;
    while StackPointer>0 do begin
     dec(StackPointer);
     CurrentNodeIndex:=Stack[StackPointer];
     if (CurrentNodeIndex>=0) and (Nodes[CurrentNodeIndex].TriangleIndex>=0) then begin
      TriangleIndex:=Nodes[CurrentNodeIndex].TriangleIndex;
      Nodes[CurrentNodeIndex].AABB:=TriangleAABBs[TriangleIndex];
      TriangleIndex:=Triangles[TriangleIndex].Next;
      ParentCount:=1;
      while TriangleIndex>=0 do begin
       Nodes[CurrentNodeIndex].AABB:=AABBCombine(Nodes[CurrentNodeIndex].AABB,TriangleAABBs[TriangleIndex]);
       inc(ParentCount);
       TriangleIndex:=Triangles[TriangleIndex].Next;
      end;
      if ParentCount>3 then begin
       Center:=Vector3Avg(Nodes[CurrentNodeIndex].AABB.Min,Nodes[CurrentNodeIndex].AABB.Max);
       TriangleIndex:=Nodes[CurrentNodeIndex].TriangleIndex;
       Count:=0;
       while TriangleIndex>=0 do begin
        v0:=@Vertices[Triangles[TriangleIndex].Vertices[0]];
        v1:=@Vertices[Triangles[TriangleIndex].Vertices[1]];
        v2:=@Vertices[Triangles[TriangleIndex].Vertices[2]];
        Points[0,Count]:=v0^.x;
        Points[1,Count]:=v0^.y;
        Points[2,Count]:=v0^.z;
        Points[0,Count+1]:=v1^.x;
        Points[1,Count+1]:=v1^.y;
        Points[2,Count+1]:=v1^.z;
        Points[0,Count+2]:=v2^.x;
        Points[1,Count+2]:=v2^.y;
        Points[2,Count+2]:=v2^.z;
        inc(Count,3);
        TriangleIndex:=Triangles[TriangleIndex].Next;
       end;
       if Count>1 then begin
        DirectIntroSort(@Points[0,0],0,Count-1,SizeOf(TKraftScalar),@CompareFloat);
        DirectIntroSort(@Points[0,1],0,Count-1,SizeOf(TKraftScalar),@CompareFloat);
        DirectIntroSort(@Points[0,2],0,Count-1,SizeOf(TKraftScalar),@CompareFloat);
        Median.x:=Points[0,Count shr 1];
        Median.y:=Points[1,Count shr 1];
        Median.z:=Points[2,Count shr 1];
       end else begin
        Median:=Center;
       end;
       BestAxis:=-1;
       BestBalance:=$7fffffff;
       for AxisCounter:=0 to 5 do begin
        if AxisCounter>2 then begin
         Axis:=AxisCounter-3;
        end else begin
         Axis:=AxisCounter;
        end;
        LeftCount:=0;
        RightCount:=0;
        LeftAABB:=Nodes[CurrentNodeIndex].AABB;
        RightAABB:=Nodes[CurrentNodeIndex].AABB;
        if AxisCounter>2 then begin
         LeftAABB.Max.xyz[Axis]:=Median.xyz[Axis];
         RightAABB.Min.xyz[Axis]:=Median.xyz[Axis];
        end else begin
         LeftAABB.Max.xyz[Axis]:=Center.xyz[Axis];
         RightAABB.Min.xyz[Axis]:=Center.xyz[Axis];
        end;
        TriangleIndex:=Nodes[CurrentNodeIndex].TriangleIndex;
        while TriangleIndex>=0 do begin
         if Vector3Avg(TriangleAABBs[TriangleIndex].Min,TriangleAABBs[TriangleIndex].Max).xyz[Axis]<RightAABB.Min.xyz[Axis] then begin
          inc(LeftCount);
         end else begin
          inc(RightCount);
         end;
         TriangleIndex:=Triangles[TriangleIndex].Next;
        end;
        if (LeftCount>0) and (RightCount>0) then begin
         Balance:=abs(RightCount-LeftCount);
         if BestBalance>Balance then begin
          BestBalance:=Balance;
          BestAxis:=AxisCounter;
         end;
        end;
       end;
       if BestAxis>=0 then begin
        LeftNodeIndex:=CountNodes;
        RightNodeIndex:=CountNodes+1;
        inc(CountNodes,2);
        if CountNodes>=length(Nodes) then begin
         SetLength(Nodes,RoundUpToPowerOfTwo(CountNodes));
        end;
        LeftAABB:=Nodes[CurrentNodeIndex].AABB;
        RightAABB:=Nodes[CurrentNodeIndex].AABB;
        TriangleIndex:=Nodes[CurrentNodeIndex].TriangleIndex;
        Nodes[LeftNodeIndex].TriangleIndex:=-1;
        Nodes[RightNodeIndex].TriangleIndex:=-1;
        Nodes[CurrentNodeIndex].TriangleIndex:=-1;
        if BestAxis>2 then begin
         dec(BestAxis,3);
         LeftAABB.Max.xyz[BestAxis]:=Median.xyz[BestAxis];
         RightAABB.Min.xyz[BestAxis]:=Median.xyz[BestAxis];
        end else begin
         LeftAABB.Max.xyz[BestAxis]:=Center.xyz[BestAxis];
         RightAABB.Min.xyz[BestAxis]:=Center.xyz[BestAxis];
        end;
        Nodes[LeftNodeIndex].AABB:=LeftAABB;
        Nodes[RightNodeIndex].AABB:=RightAABB;
        while TriangleIndex>=0 do begin
         NextTriangleIndex:=Triangles[TriangleIndex].Next;
         if Vector3Avg(TriangleAABBs[TriangleIndex].Min,TriangleAABBs[TriangleIndex].Max).xyz[BestAxis]<RightAABB.Min.xyz[BestAxis] then begin
          TargetNodeIndex:=LeftNodeIndex;
         end else begin
          TargetNodeIndex:=RightNodeIndex;
         end;
         Triangles[TriangleIndex].Next:=Nodes[TargetNodeIndex].TriangleIndex;
         if Nodes[TargetNodeIndex].TriangleIndex<0 then begin
          Nodes[TargetNodeIndex].AABB:=TriangleAABBs[TriangleIndex];
         end else begin
          Nodes[TargetNodeIndex].AABB:=AABBCombine(Nodes[TargetNodeIndex].AABB,TriangleAABBs[TriangleIndex]);
         end;
         Nodes[TargetNodeIndex].TriangleIndex:=TriangleIndex;
         TriangleIndex:=NextTriangleIndex;
        end;
        Nodes[CurrentNodeIndex].Children[0]:=LeftNodeIndex;
        Nodes[CurrentNodeIndex].Children[1]:=RightNodeIndex;
        Nodes[LeftNodeIndex].Children[0]:=-1;
        Nodes[LeftNodeIndex].Children[1]:=-1;
        Nodes[RightNodeIndex].Children[0]:=-1;
        Nodes[RightNodeIndex].Children[1]:=-1;
        if (StackPointer+2)>=length(Stack) then begin
         SetLength(Stack,RoundUpToPowerOfTwo(StackPointer+2));
        end;
        Stack[StackPointer+0]:=RightNodeIndex;
        Stack[StackPointer+1]:=LeftNodeIndex;
        inc(StackPointer,2);
       end;
      end;
     end;
    end;
    SetLength(Nodes,CountNodes);
    begin
     CountSkipListNodes:=0;
     if Root>=0 then begin
      begin
       // Pass 1 - Counting
       NewStackCapacity:=RoundUpToPowerOfTwo(CountNodes*4);
       if NewStackCapacity>length(Stack) then begin
        SetLength(Stack,NewStackCapacity);
       end;
       Stack[0]:=Root;
       StackPointer:=1;
       while StackPointer>0 do begin
        dec(StackPointer);
        NodeID:=Stack[StackPointer];
        if (NodeID>=0) and (NodeID<CountNodes) then begin
         Node:=@Nodes[NodeID];
         inc(CountSkipListNodes);
         if Node^.Children[0]>=0 then begin
          NewStackCapacity:=RoundUpToPowerOfTwo(StackPointer+2);
          if NewStackCapacity>length(Stack) then begin
           SetLength(Stack,NewStackCapacity);
          end;
          Stack[StackPointer+0]:=Node^.Children[1];
          Stack[StackPointer+1]:=Node^.Children[0];
          inc(StackPointer,2);
         end;
        end;
       end;
      end;
      begin
       // Pass 2 - Resize arrays
       SetLength(SkipListNodes,CountSkipListNodes);
      end;
      begin
       // Pass 3 - Fill arrays
       CountSkipListNodes:=0;
       Stack[0]:=Root;
       Stack[1]:=0;
       Stack[2]:=0;
       StackPointer:=3;
       while StackPointer>0 do begin
        dec(StackPointer,3);
        NodeID:=Stack[StackPointer];
        Pass:=Stack[StackPointer+1];
        Index:=Stack[StackPointer+2];
        if (NodeID>=0) and (NodeID<CountNodes) then begin
         Node:=@Nodes[NodeID];
         case Pass of
          0:begin
           Index:=CountSkipListNodes;
           inc(CountSkipListNodes);
           SkipListNode:=@SkipListNodes[Index];
           SkipListNode^.AABB.Min:=Node^.AABB.Min;
           SkipListNode^.AABB.Max:=Node^.AABB.Max;
           SkipListNode^.SkipToNodeIndex:=-1;
           if Node^.TriangleIndex>=0 then begin
            SkipListNode^.TriangleIndex:=Node^.TriangleIndex;
           end else begin
            SkipListNode^.TriangleIndex:=-1;
           end;
           if Node^.Children[0]>=0 then begin
            NewStackCapacity:=RoundUpToPowerOfTwo(StackPointer+9);
            if NewStackCapacity>length(Stack) then begin
             SetLength(Stack,NewStackCapacity);
            end;
            Stack[StackPointer+0]:=NodeID;
            Stack[StackPointer+1]:=1;
            Stack[StackPointer+2]:=Index;
            Stack[StackPointer+3]:=Node^.Children[1];
            Stack[StackPointer+4]:=0;
            Stack[StackPointer+5]:=0;
            Stack[StackPointer+6]:=Node^.Children[0];
            Stack[StackPointer+7]:=0;
            Stack[StackPointer+8]:=0;
            inc(StackPointer,9);
           end else begin
            NewStackCapacity:=RoundUpToPowerOfTwo(StackPointer+3);
            if NewStackCapacity>length(Stack) then begin
             SetLength(Stack,NewStackCapacity);
            end;
            Stack[StackPointer+0]:=NodeID;
            Stack[StackPointer+1]:=1;
            Stack[StackPointer+2]:=Index;
            inc(StackPointer,3);
           end;
          end;
          1:begin
           SkipListNode:=@SkipListNodes[Index];
           SkipListNode^.SkipToNodeIndex:=CountSkipListNodes;
          end;
         end;
        end;
       end;
      end;
     end;
    end;
   finally
    SetLength(Stack,0);
   end;
  end else begin
   SetLength(TriangleAABBs,0);
   SetLength(Nodes,0);
   SetLength(Points[0],0);
   SetLength(Points[1],0);
   SetLength(Points[2],0);
  end;
  for Index:=0 to CountVertices-1 do begin
   if Index=0 then begin
    AABB.Min:=Vertices[Index];
    AABB.Max:=Vertices[Index];
   end else begin
    AABB:=AABBCombineVector3(AABB,Vertices[Index]);
   end;
  end;
 end;
end;

procedure TKraftMassData.Adjust(const NewMass:TKraftScalar);
begin
 Matrix3x3ScalarMul(Inertia,NewMass/Mass);
 Mass:=NewMass;
end;

procedure TKraftMassData.Add(const WithMassData:TKraftMassData);
begin
 Center:=Vector3ScalarMul(Vector3Add(Vector3ScalarMul(Center,Mass),Vector3ScalarMul(WithMassData.Center,WithMassData.Mass)),1.0/(Mass+WithMassData.Mass));
 Mass:=Mass+WithMassData.Mass;
 Matrix3x3Add(Inertia,WithMassData.Inertia);
end;

procedure TKraftMassData.Rotate(const WithMatrix:TKraftMatrix3x3);
begin
 if not (SameValue(WithMatrix[0,0],1.0) and SameValue(WithMatrix[0,1],0.0) and SameValue(WithMatrix[0,2],0.0) and
         SameValue(WithMatrix[1,0],0.0) and SameValue(WithMatrix[1,1],1.0) and SameValue(WithMatrix[1,2],0.0) and
         SameValue(WithMatrix[2,0],0.0) and SameValue(WithMatrix[2,1],0.0) and SameValue(WithMatrix[2,2],1.0)) then begin
  Inertia:=Matrix3x3TermMul(Matrix3x3TermMul(WithMatrix,Inertia),Matrix3x3TermTranspose(WithMatrix));
  Inertia[1,0]:=Inertia[0,1];
  Inertia[2,0]:=Inertia[0,2];
  Inertia[2,1]:=Inertia[1,2];
  Vector3MatrixMul(Center,WithMatrix);
 end;
end;

procedure TKraftMassData.Translate(const WithVector:TKraftVector3);
var mc,mca:TKraftMatrix3x3;
    ca:TKraftVector3;
begin
 if not IsZero(Vector3LengthSquared(WithVector)) then begin
  mc[0,0]:=0.0;
  mc[0,1]:=-Center.z;
  mc[0,2]:=Center.y;
{$ifdef SIMD}
  mc[0,3]:=0.0;
{$endif}
  mc[1,0]:=Center.z;
  mc[1,1]:=0.0;
  mc[1,2]:=-Center.x;
{$ifdef SIMD}
  mc[1,3]:=0.0;
{$endif}
  mc[2,0]:=-Center.y;
  mc[2,1]:=Center.x;
  mc[2,2]:=0.0;
{$ifdef SIMD}
  mc[2,3]:=0.0;
{$endif}
  ca:=Vector3Add(Center,WithVector);
  mca[0,0]:=0.0;
  mca[0,1]:=-ca.z;
  mca[0,2]:=ca.y;
{$ifdef SIMD}
  mca[0,3]:=0.0;
{$endif}
  mca[1,0]:=ca.z;
  mca[1,1]:=0.0;
  mca[1,2]:=-ca.x;
{$ifdef SIMD}
  mca[1,3]:=0.0;
{$endif}
  mca[2,0]:=-ca.y;
  mca[2,1]:=ca.x;
  mca[2,2]:=0.0;
{$ifdef SIMD}
  mca[2,3]:=0.0;
{$endif}
  Inertia:=Matrix3x3TermAdd(Inertia,Matrix3x3TermScalarMul(Matrix3x3TermSub(Matrix3x3TermMul(mc,mc),Matrix3x3TermMul(mca,mca)),Mass));
  Inertia[1,0]:=Inertia[0,1];
  Inertia[2,0]:=Inertia[0,2];
  Inertia[2,1]:=Inertia[1,2];
  Center:=Vector3Add(Center,WithVector);
 end;
end;

procedure TKraftMassData.Transform(const WithMatrix:TKraftMatrix4x4);
begin
 Rotate(Matrix3x3(WithMatrix));
 Translate(Vector3(WithMatrix[3,0],WithMatrix[3,1],WithMatrix[3,2]));
end;
{var TempLocalCenter,a,b,c:TKraftVector3;
    Identity:TKraftMatrix3x3;
begin

 TempLocalCenter.x:=WithMatrix[3,0];
 TempLocalCenter.y:=WithMatrix[3,1];
 TempLocalCenter.z:=WithMatrix[3,2];

 Inertia:=Matrix3x3TermMul(Matrix3x3TermMul(Matrix3x3(WithMatrix),Inertia),Matrix3x3TermTranspose(Matrix3x3(WithMatrix)));
 Identity:=Matrix3x3Identity;
 Matrix3x3ScalarMul(Identity,Vector3Dot(TempLocalCenter,TempLocalCenter));
 a:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.x);
 b:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.y);
 c:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.z);
 Identity[0,0]:=(Identity[0,0]-a.x)*Mass;
 Identity[0,1]:=(Identity[0,1]-a.y)*Mass;
 Identity[0,2]:=(Identity[0,2]-a.z)*Mass;
 Identity[0,0]:=(Identity[1,0]-b.x)*Mass;
 Identity[1,1]:=(Identity[1,1]-b.y)*Mass;
 Identity[1,2]:=(Identity[1,2]-b.z)*Mass;
 Identity[2,0]:=(Identity[2,0]-c.x)*Mass;
 Identity[2,1]:=(Identity[2,1]-c.y)*Mass;
 Identity[2,2]:=(Identity[2,2]-c.z)*Mass;
 Matrix3x3Sub(Inertia,Identity);

 Center:=Vector3Add(Center,TempLocalCenter);
end;{}

constructor TKraftShape.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody);
begin
 inherited Create;

 ShapeType:=kstUnknown;

 Physics:=APhysics;

 Physics.NewShapes:=true;

 RigidBody:=ARigidBody;

 if assigned(RigidBody) then begin
  if assigned(RigidBody.ShapeLast) then begin
   RigidBody.ShapeLast.ShapeNext:=self;
   ShapePrevious:=RigidBody.ShapeLast;
  end else begin
   RigidBody.ShapeFirst:=self;
   ShapePrevious:=nil;
  end;
  RigidBody.ShapeLast:=self;
  ShapeNext:=nil;

  inc(RigidBody.ShapeCount);
 end;

 Flags:=[];

 IsMesh:=false;

 Friction:=0.4;

 Restitution:=0.2;

 Density:=1.0;

 UserData:=nil;

 StaticAABBTreeProxy:=-1;
 SleepingAABBTreeProxy:=-1;
 DynamicAABBTreeProxy:=-1;
 KinematicAABBTreeProxy:=-1;

 ShapeAABB.Min:=Vector3Origin;
 ShapeAABB.Max:=Vector3Origin;

 WorldAABB.Min:=Vector3Origin;
 WorldAABB.Max:=Vector3Origin;

 LastWorldAABB.Min:=Vector3Origin;
 LastWorldAABB.Max:=Vector3Origin;

 LocalTransform:=Matrix4x4Identity;

 WorldTransform:=Matrix4x4Identity;

 LastWorldTransform:=Matrix4x4Identity;

 InterpolatedWorldTransform:=Matrix4x4Identity;

 LocalCentroid:=Vector3Origin;

 LocalCenterOfMass:=Vector3Origin;

 FillChar(MassData,SizeOf(TKraftMassData),AnsiChar(#0));

 FeatureRadius:=0.0;

 ContinuousMinimumRadiusScaleFactor:=0.0;

{$ifdef DebugDraw}
 DrawDisplayList:=0;
{$endif}

 OnContactBegin:=nil;
 OnContactEnd:=nil;
 OnContactStay:=nil;

end;

destructor TKraftShape.Destroy;
var ContactPairEdge,NextContactPairEdge:PKraftContactPairEdge;
    ContactPair:PKraftContactPair;
begin

{$ifdef DebugDraw}
 if DrawDisplayList<>0 then begin
  glDeleteLists(DrawDisplayList,1);
  DrawDisplayList:=0;
 end;
{$endif}

 if assigned(RigidBody) then begin
  ContactPairEdge:=RigidBody.ContactPairEdgeFirst;
  while assigned(ContactPairEdge) do begin
   ContactPair:=ContactPairEdge^.ContactPair;
   NextContactPairEdge:=ContactPairEdge^.Next;
   if (ContactPair^.Shapes[0]=self) or (ContactPair^.Shapes[1]=self) then begin
    Physics.ContactManager.RemoveContact(ContactPair);
   end;
   ContactPairEdge:=NextContactPairEdge;
  end;
 end;

 if StaticAABBTreeProxy>=0 then begin
  Physics.StaticAABBTree.DestroyProxy(StaticAABBTreeProxy);
  StaticAABBTreeProxy:=-1;
 end;

 if SleepingAABBTreeProxy>=0 then begin
  Physics.SleepingAABBTree.DestroyProxy(SleepingAABBTreeProxy);
  SleepingAABBTreeProxy:=-1;
 end;

 if DynamicAABBTreeProxy>=0 then begin
  Physics.DynamicAABBTree.DestroyProxy(DynamicAABBTreeProxy);
  DynamicAABBTreeProxy:=-1;
 end;

 if KinematicAABBTreeProxy>=0 then begin
  Physics.KinematicAABBTree.DestroyProxy(KinematicAABBTreeProxy);
  KinematicAABBTreeProxy:=-1;
 end;

 if assigned(RigidBody) then begin
  if assigned(ShapePrevious) then begin
   ShapePrevious.ShapeNext:=ShapeNext;
  end else if RigidBody.ShapeFirst=self then begin
   RigidBody.ShapeFirst:=ShapeNext;
  end;
  if assigned(ShapeNext) then begin
   ShapeNext.ShapePrevious:=ShapePrevious;
  end else if RigidBody.ShapeLast=self then begin
   RigidBody.ShapeLast:=ShapePrevious;
  end;
  ShapePrevious:=nil;
  ShapeNext:=nil;

  dec(RigidBody.ShapeCount);
 end;

 inherited Destroy;
end;

procedure TKraftShape.UpdateShapeAABB;
begin
end;

procedure TKraftShape.FillMassData(BodyInertiaTensor:TKraftMatrix3x3;const LocalTransform:TKraftMatrix4x4;const Mass,Volume:TKraftScalar);
var TempLocalCenter,a,b,c:TKraftVector3;
    Identity:TKraftMatrix3x3;
begin

 TempLocalCenter.x:=LocalTransform[3,0];
 TempLocalCenter.y:=LocalTransform[3,1];
 TempLocalCenter.z:=LocalTransform[3,2];

 BodyInertiaTensor:=Matrix3x3TermMul(Matrix3x3TermMul(Matrix3x3(LocalTransform),BodyInertiaTensor),Matrix3x3TermTranspose(Matrix3x3(LocalTransform)));
 Identity:=Matrix3x3Identity;
 Matrix3x3ScalarMul(Identity,Vector3Dot(TempLocalCenter,TempLocalCenter));
 a:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.x);
 b:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.y);
 c:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.z);
 Identity[0,0]:=(Identity[0,0]-a.x)*Mass;
 Identity[0,1]:=(Identity[0,1]-a.y)*Mass;
 Identity[0,2]:=(Identity[0,2]-a.z)*Mass;
 Identity[0,0]:=(Identity[1,0]-b.x)*Mass;
 Identity[1,1]:=(Identity[1,1]-b.y)*Mass;
 Identity[1,2]:=(Identity[1,2]-b.z)*Mass;
 Identity[2,0]:=(Identity[2,0]-c.x)*Mass;
 Identity[2,1]:=(Identity[2,1]-c.y)*Mass;
 Identity[2,2]:=(Identity[2,2]-c.z)*Mass;
 Matrix3x3Sub(BodyInertiaTensor,Identity);

 MassData.Center:=TempLocalCenter;
 MassData.Inertia:=BodyInertiaTensor;
 MassData.Mass:=Mass;
 MassData.Volume:=Volume;
 MassData.Count:=1;

end;

procedure TKraftShape.CalculateMassData;
begin
end;

procedure TKraftShape.SynchronizeTransform;
begin
 if assigned(RigidBody) then begin
  WorldTransform:=Matrix4x4TermMul(LocalTransform,RigidBody.WorldTransform);
 end else begin
  WorldTransform:=LocalTransform;
 end;
end;

procedure TKraftShape.SynchronizeProxies;
var Updated,NeedUpdate:boolean;
    WorldCenterOfMass,WorldDisplacement,WorldBoundsExpansion,TempPoint:TKraftVector3;
    TempAABB:TKraftAABB;
    AABBMaxExpansion:TKraftScalar;
begin

 if assigned(RigidBody) then begin
  WorldTransform:=Matrix4x4TermMul(LocalTransform,RigidBody.WorldTransform);
 end else begin
  WorldTransform:=LocalTransform;
 end;
 WorldCenterOfMass:=Vector3TermMatrixMul(LocalCenterOfMass,WorldTransform);

 case ShapeType of
  kstSphere:begin
   WorldAABB.Min:=Vector3Sub(WorldCenterOfMass,Vector3(TKraftShapeSphere(self).Radius,TKraftShapeSphere(self).Radius,TKraftShapeSphere(self).Radius));
   WorldAABB.Max:=Vector3Add(WorldCenterOfMass,Vector3(TKraftShapeSphere(self).Radius,TKraftShapeSphere(self).Radius,TKraftShapeSphere(self).Radius));
  end;
  kstCapsule:begin
   TempPoint:=Vector3Sub(WorldCenterOfMass,Vector3ScalarMul(Vector3(WorldTransform[1,0],WorldTransform[1,1],WorldTransform[1,2]),(TKraftShapeCapsule(self).Height*0.5)));
   WorldAABB.Min:=Vector3Sub(TempPoint,Vector3(TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius));
   WorldAABB.Max:=Vector3Add(TempPoint,Vector3(TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius));
   TempPoint:=Vector3Add(WorldCenterOfMass,Vector3ScalarMul(Vector3(WorldTransform[1,0],WorldTransform[1,1],WorldTransform[1,2]),(TKraftShapeCapsule(self).Height*0.5)));
   TempAABB.Min:=Vector3Sub(TempPoint,Vector3(TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius));
   TempAABB.Max:=Vector3Add(TempPoint,Vector3(TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius,TKraftShapeCapsule(self).Radius));
   WorldAABB:=AABBCombine(WorldAABB,TempAABB);
  end;
  else begin
   WorldAABB:=AABBTransform(ShapeAABB,WorldTransform);
  end;
 end;

 if assigned(RigidBody) then begin

  WorldDisplacement:=Vector3ScalarMul(RigidBody.LinearVelocity,Physics.WorldDeltaTime);
  if Vector3LengthSquared(WorldDisplacement)<Vector3LengthSquared(RigidBody.WorldDisplacement) then begin
   WorldDisplacement:=RigidBody.WorldDisplacement;
  end;

  WorldBoundsExpansion:=Vector3ScalarMul(Vector3(AngularMotionDisc,AngularMotionDisc,AngularMotionDisc),Vector3Length(RigidBody.AngularVelocity)*Physics.WorldDeltaTime*AABB_MULTIPLIER);

  AABBMaxExpansion:=Max(AABB_MAX_EXPANSION,ShapeSphere.Radius*AABB_MAX_EXPANSION);

  if Vector3LengthSquared(WorldDisplacement)>sqr(AABBMaxExpansion) then begin
   Vector3Scale(WorldDisplacement,AABBMaxExpansion/Vector3Length(WorldDisplacement));
  end;
  if Vector3LengthSquared(WorldBoundsExpansion)>sqr(AABBMaxExpansion) then begin
   Vector3Scale(WorldBoundsExpansion,AABBMaxExpansion/Vector3Length(WorldBoundsExpansion));
  end;

  WorldAABB:=AABBStretch(WorldAABB,WorldDisplacement,WorldBoundsExpansion);

  Updated:=not (Vector3Compare(WorldAABB.Min,LastWorldAABB.Min) and Vector3Compare(WorldAABB.Max,LastWorldAABB.Max));
  LastWorldAABB:=WorldAABB;

  if (RigidBody.RigidBodyType<>krbtStatic) and (StaticAABBTreeProxy>=0) then begin
   Physics.StaticAABBTree.DestroyProxy(StaticAABBTreeProxy);
   StaticAABBTreeProxy:=-1;
  end else if RigidBody.RigidBodyType=krbtStatic then begin
   NeedUpdate:=Updated;
   if StaticAABBTreeProxy<0 then begin
    StaticAABBTreeProxy:=Physics.StaticAABBTree.CreateProxy(WorldAABB,self);
    NeedUpdate:=true;
   end else if Physics.StaticAABBTree.MoveProxy(StaticAABBTreeProxy,WorldAABB,Vector3Origin,Vector3Origin) then begin
    NeedUpdate:=true;
   end;
   if NeedUpdate then begin
    Physics.BroadPhase.StaticBufferMove(StaticAABBTreeProxy);
   end;
  end;

  if ((RigidBody.RigidBodyType<>krbtDynamic) or ((RigidBody.Flags*[krbfAwake,krbfActive])=[krbfAwake,krbfActive])) and (SleepingAABBTreeProxy>=0) then begin
   Physics.SleepingAABBTree.DestroyProxy(SleepingAABBTreeProxy);
   SleepingAABBTreeProxy:=-1;
  end else if (RigidBody.RigidBodyType=krbtDynamic) and ((RigidBody.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive]) then begin
   NeedUpdate:=Updated;
   if SleepingAABBTreeProxy<0 then begin
    SleepingAABBTreeProxy:=Physics.SleepingAABBTree.CreateProxy(WorldAABB,self);
    NeedUpdate:=true;
   end else if Physics.SleepingAABBTree.MoveProxy(SleepingAABBTreeProxy,WorldAABB,Vector3Origin,Vector3Origin) then begin
    NeedUpdate:=true;
   end;
   if NeedUpdate then begin
    Physics.BroadPhase.SleepingBufferMove(SleepingAABBTreeProxy);
   end;
  end;

  if ((RigidBody.RigidBodyType<>krbtDynamic) or ((RigidBody.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive])) and (DynamicAABBTreeProxy>=0) then begin
   Physics.DynamicAABBTree.DestroyProxy(DynamicAABBTreeProxy);
   DynamicAABBTreeProxy:=-1;
  end else if (RigidBody.RigidBodyType=krbtDynamic) and ((RigidBody.Flags*[krbfAwake,krbfActive])=[krbfAwake,krbfActive]) then begin
   NeedUpdate:=Updated;
   if DynamicAABBTreeProxy<0 then begin
    DynamicAABBTreeProxy:=Physics.DynamicAABBTree.CreateProxy(WorldAABB,self);
    NeedUpdate:=true;
   end else if Physics.DynamicAABBTree.MoveProxy(DynamicAABBTreeProxy,WorldAABB,WorldDisplacement,WorldBoundsExpansion) then begin
    NeedUpdate:=true;
   end;
   if NeedUpdate then begin
    Physics.BroadPhase.DynamicBufferMove(DynamicAABBTreeProxy);
   end;
  end;

  if (RigidBody.RigidBodyType<>krbtKinematic) and (KinematicAABBTreeProxy>=0) then begin
   Physics.KinematicAABBTree.DestroyProxy(KinematicAABBTreeProxy);
   KinematicAABBTreeProxy:=-1;
  end else if RigidBody.RigidBodyType=krbtKinematic then begin
   NeedUpdate:=Updated;
   if KinematicAABBTreeProxy<0 then begin
    KinematicAABBTreeProxy:=Physics.KinematicAABBTree.CreateProxy(WorldAABB,self);
    NeedUpdate:=true;
   end else if Physics.KinematicAABBTree.MoveProxy(KinematicAABBTreeProxy,WorldAABB,RigidBody.WorldDisplacement,Vector3Origin) then begin
    NeedUpdate:=true;
   end;
   if NeedUpdate then begin
    Physics.BroadPhase.KinematicBufferMove(KinematicAABBTreeProxy);
   end;
  end;

 end;

end;

procedure TKraftShape.Finish;
begin
 CalculateMassData;
 UpdateShapeAABB;
 ShapeSphere:=SphereFromAABB(ShapeAABB);
 AngularMotionDisc:=Vector3Length(ShapeSphere.Center)+ShapeSphere.Radius;
end;

function TKraftShape.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftShape.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftShape.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
begin
 result:=-1;
end;

function TKraftShape.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalCentroid,Transform);
end;

function TKraftShape.TestPoint(const p:TKraftVector3):boolean;
begin
 result:=false;
end;

function TKraftShape.RayCast(var RayCastData:TKraftRaycastData):boolean;
begin
 result:=false;
end;

procedure TKraftShape.StoreWorldTransform;
begin
 LastWorldTransform:=WorldTransform;
end;

procedure TKraftShape.InterpolateWorldTransform(const Alpha:TKraftScalar);
begin
 InterpolatedWorldTransform:=Matrix4x4Slerp(LastWorldTransform,WorldTransform,Alpha);
end;

{$ifdef DebugDraw}
procedure TKraftShape.Draw(const CameraMatrix:TKraftMatrix4x4);
begin
end;
{$endif}

constructor TKraftShapeSphere.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const ARadius:TKraftScalar);
begin
 Radius:=ARadius;
 inherited Create(APhysics,ARigidBody);
 ShapeType:=kstSphere;
 FeatureRadius:=ARadius;
end;

destructor TKraftShapeSphere.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftShapeSphere.UpdateShapeAABB;
begin
 ShapeAABB.Min.x:=-Radius;
 ShapeAABB.Min.y:=-Radius;
 ShapeAABB.Min.z:=-Radius;
 ShapeAABB.Max.x:=Radius;
 ShapeAABB.Max.y:=Radius;
 ShapeAABB.Max.z:=Radius;
end;

procedure TKraftShapeSphere.CalculateMassData;
var Mass,Volume:TKraftScalar;
    BodyInertiaTensor:TKraftMatrix3x3;
begin
 Volume:=((Radius*Radius*Radius)*pi)*(4.0/3.0);
 Mass:=Volume*Density;
 BodyInertiaTensor[0,0]:=Mass*(sqr(Radius)*0.4);
 BodyInertiaTensor[0,1]:=0.0;
 BodyInertiaTensor[0,2]:=0.0;
 BodyInertiaTensor[1,0]:=0.0;
 BodyInertiaTensor[1,1]:=Mass*(sqr(Radius)*0.4);
 BodyInertiaTensor[1,2]:=0.0;
 BodyInertiaTensor[2,0]:=0.0;
 BodyInertiaTensor[2,1]:=0.0;
 BodyInertiaTensor[2,2]:=Mass*(sqr(Radius)*0.4);
 FillMassData(BodyInertiaTensor,LocalTransform,Mass,Volume);
end;

function TKraftShapeSphere.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
begin
 result:=Vector3ScalarMul(Vector3SafeNorm(Direction),Radius);
end;

function TKraftShapeSphere.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftShapeSphere.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
begin
 result:=0;
end;

function TKraftShapeSphere.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=PKraftVector3(pointer(@Transform[3,0]))^;
end;

function TKraftShapeSphere.TestPoint(const p:TKraftVector3):boolean;
begin
 result:=Vector3Length(Vector3TermMatrixMulInverted(p,WorldTransform))<=Radius;
end;

function TKraftShapeSphere.RayCast(var RayCastData:TKraftRaycastData):boolean;
var Origin,Direction,m:TKraftVector3;
    p,d,s1,s2,t:TKraftScalar;
begin
 result:=false;
 Origin:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 Direction:=Vector3SafeNorm(Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform));
 m:=Vector3Sub(Origin,Vector3Origin);
 p:=-Vector3Dot(m,Direction);
 d:=(sqr(p)-Vector3LengthSquared(m))+sqr(Radius);
 if d>0.0 then begin
  d:=sqrt(d);
  s1:=p-d;
  s2:=p+d;
  if s2>0.0 then begin
   if s1<0.0 then begin
    t:=s2;
   end else begin
    t:=s1;
   end;
   if (t>=0.0) and (t<=RayCastData.MaxTime) then begin
    RayCastData.TimeOfImpact:=t;
    RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,t)),WorldTransform);
    RayCastData.Normal:=Vector3NormEx(Vector3Sub(RayCastData.Point,Vector3TermMatrixMul(Vector3Origin,WorldTransform)));
    result:=true;
   end;
  end;
 end;
end;

{$ifdef DebugDraw}
procedure TKraftShapeSphere.Draw(const CameraMatrix:TKraftMatrix4x4);
const lats=16;
      longs=16;
      pi2=pi*2.0;
var i,j:longint;
    lat0,z0,zr0,lat1,z1,zr1,lng,x,y:TKraftScalar;
    ModelViewMatrix:TKraftMatrix4x4;
begin
 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  for i:=0 to lats do begin
   lat0:=pi*(((i-1)/lats)-0.5);
   z0:=sin(lat0)*Radius;
   zr0:=cos(lat0)*Radius;
   lat1:=pi*((i/lats)-0.5);
   z1:=sin(lat1)*Radius;
   zr1:=cos(lat1)*Radius;
   glBegin(GL_QUAD_STRIP);
   for j:=0 to longs do begin
    lng:=pi2*((j-1)/longs);
    x:=cos(lng);
    y:=sin(lng);
    glNormal3f(x*zr1,y*zr1,z1);
    glVertex3f(x*zr1,y*zr1,z1);
    glNormal3f(x*zr0,y*zr0,z0);
    glVertex3f(x*zr0,y*zr0,z0);
   end;
   glEnd;
  end;

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

constructor TKraftShapeCapsule.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const ARadius,AHeight:TKraftScalar);
begin
 Radius:=ARadius;
 Height:=AHeight;
 inherited Create(APhysics,ARigidBody);
 ShapeType:=kstCapsule;
 FeatureRadius:=ARadius;
end;

destructor TKraftShapeCapsule.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftShapeCapsule.UpdateShapeAABB;
begin
 ShapeAABB.Min.x:=-Radius;
 ShapeAABB.Min.y:=-(Radius+(Height*0.5));
 ShapeAABB.Min.z:=-Radius;
 ShapeAABB.Max.x:=Radius;
 ShapeAABB.Max.y:=Radius+(Height*0.5);
 ShapeAABB.Max.z:=Radius;
end;

(**)
procedure TKraftShapeCapsule.CalculateMassData;
var CylinderMass,CapMass,Mass,Volume:TKraftScalar;
    BodyInertiaTensor:TKraftMatrix3x3;
begin
 CylinderMass:=pi*sqr(Radius)*Height*Density;
 CapMass:=((4.0/3.0)*pi*Radius*Radius*Radius*density);
 Volume:=((4.0/3.0)*pi*Radius*Radius*Radius)+(Height*pi*sqr(Radius));
 Mass:=CylinderMass+CapMass;
{BodyInertiaTensor[0,0]:=((1.0/12.0)*(CylinderMass*sqr(Height)))+(0.25*CylinderMass*sqr(Radius))+(0.4*CapMass*sqr(Radius))+(CapMass*sqr(0.5*Height));
 BodyInertiaTensor[0,1]:=0.0;
 BodyInertiaTensor[0,2]:=0.0;
 BodyInertiaTensor[1,0]:=0.0;
 BodyInertiaTensor[1,1]:=((1.0/2.0)*(CylinderMass*sqr(Radius)))+(0.2*CapMass*sqr(Radius));
 BodyInertiaTensor[1,2]:=0.0;
 BodyInertiaTensor[2,0]:=0.0;
 BodyInertiaTensor[2,1]:=0.0;
 BodyInertiaTensor[2,2]:=((1.0/12.0)*(CylinderMass*sqr(Height)))+(0.25*CylinderMass*sqr(Radius))+(0.4*CapMass*sqr(Radius))+(CapMass*sqr(0.5*Height));{}
 BodyInertiaTensor[0,0]:=(CylinderMass*((0.25*CylinderMass*sqr(Radius))+((1.0/12.0)*sqr(Height))))+(CapMass*((0.4*sqr(Radius))+(0.375*(Radius*Height))+(0.25*sqr(Height))));
 BodyInertiaTensor[0,1]:=0.0;
 BodyInertiaTensor[0,2]:=0.0;
 BodyInertiaTensor[1,0]:=0.0;
 BodyInertiaTensor[1,1]:=((0.5*CylinderMass)+(0.4*CapMass))*sqr(Radius);
 BodyInertiaTensor[1,2]:=0.0;
 BodyInertiaTensor[2,0]:=0.0;
 BodyInertiaTensor[2,1]:=0.0;
 BodyInertiaTensor[2,2]:=(CylinderMass*((0.25*CylinderMass*sqr(Radius))+((1.0/12.0)*sqr(Height))))+(CapMass*((0.4*sqr(Radius))+(0.375*(Radius*Height))+(0.25*sqr(Height))));{}
 FillMassData(BodyInertiaTensor,LocalTransform,Mass,Volume);
end;(**)


(*)
procedure TKraftShapeCapsule.CalculateMassData;
const pi2Over3=(2.0/3.0)*pi;
      TwoOver5=2.0/5.0;
      OneOver12=1.0/12.0;
      OneOver2=1.0/2.0;
var Length,SquaredLength,SquaredRadius,xs,ys,zs:single;
    x,y,z:TKraftVector3;
    MassDataA,MassDataB:TKraftMassData;
    RotationMatrix:TKraftMatrix3x3;
begin
 Length:=Height;
 SquaredLength:=sqr(Length);
 SquaredRadius:=sqr(Radius);
 begin
  // Hemisphere
  MassDataA.Mass:=pi2Over3*SquaredRadius*Radius*Density;
  ys:=TwoOver5*MassDataA.Mass*SquaredRadius;
  xs:=ys+(MassDataA.Mass*Length*(((3.0*Radius)+(2.0*Length))/8.0));
  zs:=xs;
  MassDataA.Inertia[0,0]:=xs;
  MassDataA.Inertia[0,1]:=0.0;
  MassDataA.Inertia[0,2]:=0.0;
  MassDataA.Inertia[1,0]:=0.0;
  MassDataA.Inertia[1,1]:=ys;
  MassDataA.Inertia[1,2]:=0.0;
  MassDataA.Inertia[2,0]:=0.0;
  MassDataA.Inertia[2,1]:=0.0;
  MassDataA.Inertia[2,2]:=zs;
 end;
 begin
  // Cylinder
  MassDataB.Mass:=pi*SquaredRadius*Length*Density;
  xs:=OneOver12*MassDataB.Mass*((3.0*SquaredRadius)+SquaredLength);
  ys:=Oneover2*MassDataB.Mass*SquaredRadius;
  zs:=xs;
  MassDataB.Inertia[0,0]:=xs;
  MassDataB.Inertia[0,1]:=0.0;
  MassDataB.Inertia[0,2]:=0.0;
  MassDataB.Inertia[1,0]:=0.0;
  MassDataB.Inertia[1,1]:=ys;
  MassDataB.Inertia[1,2]:=0.0;
  MassDataB.Inertia[2,0]:=0.0;
  MassDataB.Inertia[2,1]:=0.0;
  MassDataB.Inertia[2,2]:=zs;
 end;
 begin
  MassData.Mass:=(MassDataA.Mass*2.0)+MassDataB.Mass;
  MassData.Inertia:=Matrix3x3TermAdd(Matrix3x3TermScalarMul(MassDataA.Inertia,2.0),MassDataB.Inertia);
 y:=Vector3NormEx(Axis);
  ComputeBasis(y,x,z);
  RotationMatrix[0,0]:=x.x;
  RotationMatrix[0,1]:=x.y;
  RotationMatrix[0,2]:=x.z;
{$ifdef SIMD}
  RotationMatrix[0,3]:=0.0;
{$endif}
  RotationMatrix[1,0]:=y.x;
  RotationMatrix[1,1]:=y.y;
  RotationMatrix[1,2]:=y.z;
{$ifdef SIMD}
  RotationMatrix[1,3]:=0.0;
{$endif}
  RotationMatrix[2,0]:=z.x;
  RotationMatrix[2,1]:=z.y;
  RotationMatrix[2,2]:=z.z;
{$ifdef SIMD}
  RotationMatrix[2,3]:=0.0;
{$endif}
  MassData.Center:=Vector3Origin;
  MassData.Inertia:=Matrix3x3TermMulTranspose(Matrix3x3TermMul(RotationMatrix,MassData.Inertia),RotationMatrix);
//  Matrix3x3Add(MassData.Inertia,Matrix3x3TermMul(Matrix3x3TermSub(Matrix3x3TermScalarMul(Matrix3x3Identity,Vector3LengthSquared(MassData.Center)),Matrix3x3OuterProduct(MassData.Center,MassData.Center)),MassData.Inertia));
  MassData.Center:=Vector3Origin;
  MassData.Volume:=((4.0/3.0)*pi*Radius*Radius*Radius)+(Height*pi*sqr(Radius));
 end;
end;(**)

function TKraftShapeCapsule.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
var Normal,p0,p1:TKraftVector3;
    HalfHeight:TKraftScalar;
begin
 Normal:=Vector3SafeNorm(Direction);
 HalfHeight:=Height*0.5;
 p0.x:=(Normal.x*Radius);
 p0.y:=(Normal.y*Radius)-HalfHeight;
 p0.z:=(Normal.z*Radius);
 p1.x:=(Normal.x*Radius);
 p1.y:=(Normal.y*Radius)+HalfHeight;
 p1.z:=(Normal.z*Radius);
 if Vector3Dot(p0,Normal)<Vector3Dot(p1,Normal) then begin
  result:=p1;
 end else begin
  result:=p0;
 end;
end;

function TKraftShapeCapsule.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 result.x:=0.0;
 case Index of
  0:begin
   result.y:=-Height*0.5;
  end;
  else begin
   result.y:=Height*0.5;
  end;
 end;
 result.z:=0.0;
end;

function TKraftShapeCapsule.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
begin
 if Direction.y<0.0 then begin
  result:=0;
 end else begin
  result:=1;
 end;
end;

function TKraftShapeCapsule.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=PKraftVector3(pointer(@Transform[3,0]))^;
end;

function TKraftShapeCapsule.TestPoint(const p:TKraftVector3):boolean;
var v:TKraftVector3;
    HalfHeight:TKraftScalar;
begin
 v:=Vector3TermMatrixMulInverted(p,WorldTransform);
 HalfHeight:=Height*0.5;
 result:=(abs(v.y)<=(HalfHeight+Radius)) and (Vector3Length(Vector3(v.x,Min(Max(v.y,-HalfHeight),HalfHeight),v.z))<=Radius);
end;

function TKraftShapeCapsule.RayCast(var RayCastData:TKraftRaycastData):boolean;
var Origin,Direction,p,m:TKraftVector3;
    Aq,Bq,Cq,t,t0,t1,y0,y1,HalfHeight,pp,d,s1,s2:TKraftScalar;
begin
 result:=false;
 Origin:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 Direction:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform));
 HalfHeight:=Height*0.5;
 Aq:=sqr(Direction.x)+sqr(Direction.z);
 Bq:=((2.0*Origin.x)*Direction.x)+((2.0*Origin.z)*Direction.z);
 Cq:=(sqr(Origin.x)+sqr(Origin.z))-sqr(Radius);
 if SolveQuadraticRoots(Aq,Bq,Cq,t0,t1) then begin
  if t0>t1 then begin
   t:=t0;
   t0:=t1;
   t1:=t;
  end;
  y0:=Origin.y+(Direction.y*t0);
  y1:=Origin.y+(Direction.y*t1);
  if y0<(-HalfHeight) then begin
   if y1>=(-HalfHeight) then begin
    // if y0 < -HalfHeight and y1 >= -HalfHeight, then the ray hits the bottom Capsule cap
    t:=y0-y1;
    if t<>0.0 then begin
     t:=t0+(((t1-t0)*(y0+HalfHeight))/t);
     if (t>=0.0) and (t<=RayCastData.MaxTime) then begin
      RayCastData.TimeOfImpact:=t;
      RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,t)),WorldTransform);
      RayCastData.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(Vector3(0.0,-1.0,0.0),WorldTransform));
      result:=true;
      exit;
     end;
    end;
   end;
  end else if y0>HalfHeight then begin
   if y1<=HalfHeight then begin
    // if y0 > HalfHeight and y1 <= HalfHeight, then the ray hits the top Capsule cap
    t:=y0-y1;
    if t<>0.0 then begin
     t:=t0+(((t1-t0)*(y0-HalfHeight))/t);
     if (t>=0.0) and (t<=RayCastData.MaxTime) then begin
      RayCastData.TimeOfImpact:=t;
      RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,t)),WorldTransform);
      RayCastData.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(Vector3(0.0,1.0,0.0),WorldTransform));
      result:=true;
      exit;
     end;
    end;
   end;
  end else begin
   if (t0>=0.0) and (t0<=RayCastData.MaxTime) then begin
    // if y0 < HalfHeight and y0 > -HalfHeight and t0 >= 0.0, then the ray intersects then Capsule wall
    RayCastData.TimeOfImpact:=t0;
    p:=Vector3Add(Origin,Vector3ScalarMul(Direction,t0));
    RayCastData.Point:=Vector3TermMatrixMul(p,WorldTransform);
    RayCastData.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(p,WorldTransform));
    result:=true;
    exit;
   end;
  end;
 end;
 begin
  m:=Vector3Sub(Origin,Vector3(0.0,-HalfHeight,0.0));
  pp:=-Vector3Dot(m,Direction);
  d:=sqr(pp)-Vector3LengthSquared(m)+sqr(Radius);
  if d>0.0 then begin
   d:=sqrt(d);
   s1:=pp-d;
   s2:=pp+d;
   if s2>0.0 then begin
    if s1<0.0 then begin
     t:=s2;
    end else begin
     t:=s1;
    end;
    if (t>=0.0) and (t<=RayCastData.MaxTime) then begin
     RayCastData.TimeOfImpact:=t;
     RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,t)),WorldTransform);
     RayCastData.Normal:=Vector3NormEx(Vector3Sub(RayCastData.Point,Vector3TermMatrixMul(Vector3(0.0,-HalfHeight,0.0),WorldTransform)));
     result:=true;
     exit;
    end;
   end;
  end;
 end;
 begin
  m:=Vector3Sub(Origin,Vector3(0.0,HalfHeight,0.0));
  pp:=-Vector3Dot(m,Direction);
  d:=sqr(pp)-Vector3LengthSquared(m)+sqr(Radius);
  if d>0.0 then begin
   d:=sqrt(d);
   s1:=pp-d;
   s2:=pp+d;
   if s2>0.0 then begin
    if s1<0.0 then begin
     t:=s2;
    end else begin
     t:=s1;
    end;
    if (t>=0.0) and (t<=RayCastData.MaxTime) then begin
     RayCastData.TimeOfImpact:=t;
     RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,t)),WorldTransform);
     RayCastData.Normal:=Vector3NormEx(Vector3Sub(RayCastData.Point,Vector3TermMatrixMul(Vector3(0.0,HalfHeight,0.0),WorldTransform)));
     result:=true;
    end;
   end;
  end;
 end;
end;

{$ifdef DebugDraw}
procedure TKraftShapeCapsule.Draw(const CameraMatrix:TKraftMatrix4x4);
const lats=16;
      longs=16;
     pi2=pi*2.0;
var ModelViewMatrix:TKraftMatrix4x4;
    i,j:longint;
    HalfHeight,lat0,y0,yr0,lat1,y1,yr1,lng,x,z,yo0,yo1:TKraftScalar;
begin
 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  HalfHeight:=Height*0.5;

  for i:=0 to lats do begin
   lat0:=pi*(((i-1)/lats)-0.5);
   y0:=sin(lat0);
   yr0:=cos(lat0);
   lat1:=pi*((i/lats)-0.5);
   y1:=sin(lat1);
   yr1:=cos(lat1);
   if y0<0.0 then begin
    yo0:=-HalfHeight;
   end else begin
    yo0:=HalfHeight;
   end;
   if y1<0.0 then begin
    yo1:=-HalfHeight;
   end else begin
    yo1:=HalfHeight;
   end;
   glBegin(GL_QUAD_STRIP);
   for j:=0 to longs do begin
    lng:=pi2*((j-1)/longs);
    x:=cos(lng);
    z:=sin(lng);
    glNormal3f(x*yr0,y0,(z*yr0));
    glVertex3f(x*yr0*Radius,yo0+(y0*Radius),z*yr0*Radius);
    glNormal3f(x*yr1,y1,(z*yr1));
    glVertex3f(x*yr1*Radius,yo1+(y1*Radius),z*yr1*Radius);
   end;
   glEnd;
  end;

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

constructor TKraftShapeConvexHull.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AConvexHull:TKraftConvexHull);
begin

 ConvexHull:=AConvexHull;

 inherited Create(APhysics,ARigidBody);

 ShapeType:=kstConvexHull;

 FeatureRadius:=0.0;

//LocalCentroid:=ConvexHull.MassData.Center;
 LocalCentroid:=ConvexHull.Centroid;

 LocalCenterOfMass:=ConvexHull.MassData.Center;

 AngularMotionDisc:=ConvexHull.AngularMotionDisc;

end;

destructor TKraftShapeConvexHull.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftShapeConvexHull.UpdateShapeAABB;
begin
 ShapeAABB:=ConvexHull.AABB;
end;

procedure TKraftShapeConvexHull.CalculateMassData;
begin
 MassData:=ConvexHull.MassData;
 MassData.Mass:=MassData.Mass*Density;
 MassData.Inertia[0,0]:=MassData.Inertia[0,0]*Density;
 MassData.Inertia[0,1]:=MassData.Inertia[0,1]*Density;
 MassData.Inertia[0,2]:=MassData.Inertia[0,2]*Density;
 MassData.Inertia[1,0]:=MassData.Inertia[1,0]*Density;
 MassData.Inertia[1,1]:=MassData.Inertia[1,1]*Density;
 MassData.Inertia[1,2]:=MassData.Inertia[1,2]*Density;
 MassData.Inertia[2,0]:=MassData.Inertia[2,0]*Density;
 MassData.Inertia[2,1]:=MassData.Inertia[2,1]*Density;
 MassData.Inertia[2,2]:=MassData.Inertia[2,2]*Density;
end;

function TKraftShapeConvexHull.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
begin
 result:=ConvexHull.GetLocalFullSupport(Vector3SafeNorm(Direction));
end;

function TKraftShapeConvexHull.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 result:=ConvexHull.GetLocalFeatureSupportVertex(Index);
end;

function TKraftShapeConvexHull.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
begin
 result:=ConvexHull.GetLocalFeatureSupportIndex(Direction);
end;

function TKraftShapeConvexHull.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin                               
 result:=Vector3TermMatrixMul(LocalCentroid,Transform);
end;

function TKraftShapeConvexHull.TestPoint(const p:TKraftVector3):boolean;
var i:longint;
begin
 result:=true;
 for i:=0 to ConvexHull.CountFaces-1 do begin
  if PlaneVectorDistance(ConvexHull.Faces[i].Plane,p)>0.0 then begin
   result:=false;
   exit;
  end;
 end;
end;

function TKraftShapeConvexHull.RayCast(var RayCastData:TKraftRaycastData):boolean;
var FaceIndex,BestFaceIndex:longint;
    Face:PKraftConvexHullFace;
    TimeFirst,TimeLast,Numerator,Denominator,Time:TKraftScalar;
    Origin,Direction:TKraftVector3;
begin
 result:=false;
 Origin:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 Direction:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform));
 if Vector3LengthSquared(Direction)>EPSILON then begin
  BestFaceIndex:=-1;
  TimeFirst:=0.0;
  TimeLast:=RayCastData.MaxTime+EPSILON;
  for FaceIndex:=0 to ConvexHull.CountFaces-1 do begin
   Face:=@ConvexHull.Faces[FaceIndex];
   Numerator:=-PlaneVectorDistance(Face^.Plane,Origin);
   Denominator:=Vector3Dot(Face^.Plane.Normal,Direction);
   if abs(Denominator)<EPSILON then begin
    if Numerator<0.0 then begin
     exit;
    end;
   end else begin
    Time:=Numerator/Denominator;
    if Denominator<0.0 then begin
     if TimeFirst<Time then begin
      TimeFirst:=Time;
      BestFaceIndex:=FaceIndex;
     end;
    end else begin
     if TimeLast>Time then begin
      TimeLast:=Time;
     end;
    end;
    if TimeFirst>TimeLast then begin
     exit;
    end;
   end;
  end;
  if (BestFaceIndex>=0) and (TimeFirst<=TimeLast) and (TimeFirst<=RayCastData.MaxTime) then begin
   RayCastData.TimeOfImpact:=TimeFirst;
   RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,TimeFirst)),WorldTransform);
   RayCastData.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(ConvexHull.Faces[BestFaceIndex].Plane.Normal,WorldTransform));
   result:=true;
  end;
 end;
end;

{$ifdef DebugDraw}
procedure TKraftShapeConvexHull.Draw(const CameraMatrix:TKraftMatrix4x4);
var i,j:longint;
    ModelViewMatrix:TKraftMatrix4x4;
    Face:PKraftConvexHullFace;
begin
 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  glBegin(GL_TRIANGLES);
  for i:=0 to ConvexHull.CountFaces-1 do begin
   Face:=@ConvexHull.Faces[i];
{$ifdef UseDouble}
   glNormal3dv(@Face^.Plane.Normal);
   for j:=1 to Face^.CountVertices-2 do begin
    glVertex3dv(@ConvexHull.Vertices[Face^.Vertices[0]].Position);
    glVertex3dv(@ConvexHull.Vertices[Face^.Vertices[j]].Position);
    glVertex3dv(@ConvexHull.Vertices[Face^.Vertices[j+1]].Position);
   end;
{$else}
   glNormal3fv(@Face^.Plane.Normal);
   for j:=1 to Face^.CountVertices-2 do begin
    glVertex3fv(@ConvexHull.Vertices[Face^.Vertices[0]].Position);
    glVertex3fv(@ConvexHull.Vertices[Face^.Vertices[j]].Position);
    glVertex3fv(@ConvexHull.Vertices[Face^.Vertices[j+1]].Position);
   end;
{$endif}
  end;
  glEnd;

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

constructor TKraftShapeBox.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AExtents:TKraftVector3);
var i:longint;
    BoxPoints:array[0..7] of TKraftVector3;
begin
 Extents:=AExtents;
 for i:=0 to length(BoxPoints)-1 do begin
  if (i and 1)<>0 then begin
   BoxPoints[i].x:=Extents.x;
  end else begin
   BoxPoints[i].x:=-Extents.x;
  end;
  if (i and 2)<>0 then begin
   BoxPoints[i].y:=Extents.y;
  end else begin
   BoxPoints[i].y:=-Extents.y;
  end;
  if (i and 4)<>0 then begin
   BoxPoints[i].z:=Extents.z;
  end else begin
   BoxPoints[i].z:=-Extents.z;
  end;
 end;
 ShapeConvexHull:=TKraftConvexHull.Create(APhysics);
 ShapeConvexHull.Load(pointer(@BoxPoints[0]),length(BoxPoints));
 ShapeConvexHull.Build;
 ShapeConvexHull.Finish;
 AngularMotionDisc:=ShapeConvexHull.AngularMotionDisc;
 inherited Create(APhysics,ARigidBody,ShapeConvexHull);
 ShapeType:=kstBox;
 FeatureRadius:=0.0;
end;

destructor TKraftShapeBox.Destroy;
begin
 ShapeConvexHull.Free;
 inherited Destroy;
end;

procedure TKraftShapeBox.UpdateShapeAABB;
begin
 ShapeAABB.Min.x:=-Extents.x;
 ShapeAABB.Min.y:=-Extents.y;
 ShapeAABB.Min.z:=-Extents.z;
 ShapeAABB.Max.x:=Extents.x;
 ShapeAABB.Max.y:=Extents.y;
 ShapeAABB.Max.z:=Extents.z;
end;

procedure TKraftShapeBox.CalculateMassData;
var Mass,Volume:TKraftScalar;
    BodyInertiaTensor:TKraftMatrix3x3;
begin
 Volume:=Extents.x*Extents.y*Extents.z;
 Mass:=Volume*Density;
 BodyInertiaTensor[0,0]:=(Mass*(sqr(Extents.y)+sqr(Extents.z)))/12.0;
 BodyInertiaTensor[0,1]:=0.0;
 BodyInertiaTensor[0,2]:=0.0;
 BodyInertiaTensor[1,0]:=0.0;
 BodyInertiaTensor[1,1]:=(Mass*(sqr(Extents.x)+sqr(Extents.z)))/12.0;
 BodyInertiaTensor[1,2]:=0.0;
 BodyInertiaTensor[2,0]:=0.0;
 BodyInertiaTensor[2,1]:=0.0;
 BodyInertiaTensor[2,2]:=(Mass*(sqr(Extents.x)+sqr(Extents.y)))/12.0;
 FillMassData(BodyInertiaTensor,LocalTransform,Mass,Volume);   
end;

function TKraftShapeBox.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
var Normal:TKraftVector3;
begin
 Normal:=Direction;
{$ifdef cpuarm}
 if Normal.x<0.0 then begin
  result.x:=-Extents.x;
 end else begin
  result.x:=Extents.x;
 end;
 if Normal.y<0.0 then begin
  result.y:=-Extents.y;
 end else begin
  result.y:=Extents.y;
 end;
 if Normal.z<0.0 then begin
  result.z:=-Extents.z;
 end else begin
  result.z:=Extents.z;
 end;
{$else}
 result.x:=Extents.x*(1-longint(longword(longword(pointer(@Normal.x)^) shr 31) shl 1));
 result.y:=Extents.y*(1-longint(longword(longword(pointer(@Normal.y)^) shr 31) shl 1));
 result.z:=Extents.z*(1-longint(longword(longword(pointer(@Normal.z)^) shr 31) shl 1));
{$endif}
end;

function TKraftShapeBox.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 result:=inherited GetLocalFeatureSupportVertex(Index);
end;

function TKraftShapeBox.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
begin
 result:=inherited GetLocalFeatureSupportIndex(Direction);
end;

function TKraftShapeBox.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=PKraftVector3(pointer(@Transform[3,0]))^;
end;

function TKraftShapeBox.TestPoint(const p:TKraftVector3):boolean;
var v:TKraftVector3;
begin
 v:=Vector3TermMatrixMulInverted(p,WorldTransform);
 result:=((v.x>=(-Extents.x)) and (v.x<=Extents.x)) and
         ((v.y>=(-Extents.y)) and (v.x<=Extents.y)) and
         ((v.z>=(-Extents.z)) and (v.x<=Extents.z));
end;

function TKraftShapeBox.RayCast(var RayCastData:TKraftRaycastData):boolean;
var s,v,h:TKraftVector3;
    lo,hi,k,Alpha:TKraftScalar;
    nlo,nhi,n:longint;
    sign:array[0..2] of TKraftScalar;
begin
 result:=false;
 s:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 v:=Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform);
 if v.x<0 then begin
  s.x:=-s.x;
  v.x:=-v.x;
  sign[0]:=1;
 end else begin
  sign[0]:=-1;
 end;
 if v.y<0 then begin
  s.y:=-s.y;
  v.y:=-v.y;
  sign[1]:=1;
 end else begin
  sign[1]:=-1;
 end;
 if v.z<0 then begin
  s.z:=-s.z;
  v.z:=-v.z;
  sign[2]:=1;
 end else begin
  sign[2]:=-1;
 end;
 h:=Extents;
 if (((s.x<-h.x) and (v.x<=0)) or (s.x>h.x)) or
    (((s.y<-h.y) and (v.y<=0)) or (s.y>h.y)) or
    (((s.z<-h.z) and (v.z<=0)) or (s.z>h.z)) then begin
  exit;
 end;
 lo:=-INFINITY;
 hi:=INFINITY;
 nlo:=0;
 nhi:=0;
 if v.x<>0.0 then begin
  k:=((-h.x)-s.x)/v.x;
  if k>lo then begin
   lo:=k;
   nlo:=0;
  end;
  k:=(h.x-s.x)/v.x;
  if k<hi then begin
   hi:=k;
   nhi:=0;
  end;
 end;
 if v.y<>0.0 then begin
  k:=((-h.y)-s.y)/v.y;
  if k>lo then begin
   lo:=k;
   nlo:=1;
  end;
  k:=(h.y-s.y)/v.y;
  if k<hi then begin
   hi:=k;
   nhi:=1;
  end;
 end;
 if v.z<>0.0 then begin
  k:=((-h.z)-s.z)/v.z;
  if k>lo then begin
   lo:=k;
   nlo:=2;
  end;
  k:=(h.z-s.z)/v.z;
  if k<hi then begin
   hi:=k;
   nhi:=2;
  end;
 end;
 if lo>hi then begin
  exit;
 end;
 if lo>=0 then begin
  Alpha:=lo;
  n:=nlo;
 end else begin
  Alpha:=hi;
  n:=nhi;
 end;
 if (Alpha<0) or (Alpha>RayCastData.MaxTime) then begin
  exit;
 end;
 RayCastData.TimeOfImpact:=Alpha;
 RayCastData.Point:=Vector3Add(RayCastData.Origin,Vector3ScalarMul(RayCastData.Direction,Alpha));
 RayCastData.Normal:=Vector3ScalarMul(Vector3(WorldTransform[n,0],WorldTransform[n,1],WorldTransform[n,2]),sign[n]);
 result:=true;
end;

{$ifdef DebugDraw}
procedure TKraftShapeBox.Draw(const CameraMatrix:TKraftMatrix4x4);
var ModelViewMatrix:TKraftMatrix4x4;
begin
 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  glBegin(GL_TRIANGLE_STRIP);
  glNormal3f(-1.0,0.0,0.0);
  glVertex3f(-Extents.x,-Extents.y,-Extents.z);
  glVertex3f(-Extents.x,-Extents.y,Extents.z);
  glVertex3f(-Extents.x,Extents.y,-Extents.z);
  glVertex3f(-Extents.x,Extents.y,Extents.z);
  glNormal3f(0.0,1.0,0.0);
  glVertex3f(Extents.x,Extents.y,-Extents.z);
  glVertex3f(Extents.x,Extents.y,Extents.z);
  glNormal3f(1.0,0.0,0.0);
  glVertex3f(Extents.x,-Extents.y,-Extents.z);
  glVertex3f(Extents.x,-Extents.y,Extents.z);
  glNormal3f(0.0,-1.0,0.0);
  glVertex3f(-Extents.x,-Extents.y,-Extents.z);
  glVertex3f(-Extents.x,-Extents.y,Extents.z);
  glEnd;
  glBegin(GL_TRIANGLE_FAN);
  glNormal3f(0.0,0.0,1.0);
  glVertex3f(-Extents.x,-Extents.y,Extents.z);
  glVertex3f(Extents.x,-Extents.y,Extents.z);
  glVertex3f(Extents.x,Extents.y,Extents.z);
  glVertex3f(-Extents.x,Extents.y,Extents.z);
  glEnd;
  glBegin(GL_TRIANGLE_FAN);
  glNormal3f(0.0,0.0,-1.0);
  glVertex3f(-Extents.x,-Extents.y,-Extents.z);
  glVertex3f(-Extents.x,Extents.y,-Extents.z);
  glVertex3f(Extents.x,Extents.y,-Extents.z);
  glVertex3f(Extents.x,-Extents.y,-Extents.z);
  glEnd;

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

const PlaneSize=32768.0;

constructor TKraftShapePlane.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const APlane:TKraftPlane);
var HullPlaneVertices:array[0..7] of TKraftVector3;
    b,p,q:TKraftVector3;
begin
 Plane:=APlane;
 GetPlaneSpace(Plane.Normal,p,q);
 PlaneCenter:=Vector3ScalarMul(Plane.Normal,Plane.Distance-(PlaneSize*0.5));
 b:=Vector3ScalarMul(Plane.Normal,Plane.Distance);
 PlaneVertices[0]:=Vector3Add(b,Vector3Add(Vector3ScalarMul(p,PlaneSize),Vector3ScalarMul(q,PlaneSize)));
 PlaneVertices[1]:=Vector3Add(b,Vector3Add(Vector3ScalarMul(p,PlaneSize),Vector3ScalarMul(q,-PlaneSize)));
 PlaneVertices[2]:=Vector3Add(b,Vector3Add(Vector3ScalarMul(p,-PlaneSize),Vector3ScalarMul(q,-PlaneSize)));
 PlaneVertices[3]:=Vector3Add(b,Vector3Add(Vector3ScalarMul(p,-PlaneSize),Vector3ScalarMul(q,PlaneSize)));
 b:=Vector3ScalarMul(Plane.Normal,PlaneSize);
 HullPlaneVertices[0]:=PlaneVertices[0];
 HullPlaneVertices[1]:=PlaneVertices[1];
 HullPlaneVertices[2]:=PlaneVertices[2];
 HullPlaneVertices[3]:=PlaneVertices[3];
 HullPlaneVertices[4]:=Vector3Sub(PlaneVertices[0],b);
 HullPlaneVertices[5]:=Vector3Sub(PlaneVertices[1],b);
 HullPlaneVertices[6]:=Vector3Sub(PlaneVertices[2],b);
 HullPlaneVertices[7]:=Vector3Sub(PlaneVertices[3],b);
//PlaneCenter:=Vector3Avg(@HullPlaneVertices[0],length(HullPlaneVertices));
 ShapeConvexHull:=TKraftConvexHull.Create(APhysics);
 ShapeConvexHull.Load(pointer(@HullPlaneVertices[0]),length(HullPlaneVertices));
 ShapeConvexHull.Build;
 ShapeConvexHull.Finish;
 AngularMotionDisc:=ShapeConvexHull.AngularMotionDisc;
 inherited Create(APhysics,ARigidBody,ShapeConvexHull);
 ShapeType:=kstPlane;
 FeatureRadius:=0.0;
end;

destructor TKraftShapePlane.Destroy;
begin
 ShapeConvexHull.Free;
 inherited Destroy;
end;

procedure TKraftShapePlane.UpdateShapeAABB;
var b:TKraftVector3;
begin
 b:=Vector3ScalarMul(Plane.Normal,Plane.Distance-PlaneSize);
 ShapeAABB.Min.x:=Min(Min(Min(Min(PlaneVertices[0].x,PlaneVertices[1].x),PlaneVertices[2].x),PlaneVertices[3].x),b.x)-0.1;
 ShapeAABB.Min.y:=Min(Min(Min(Min(PlaneVertices[0].y,PlaneVertices[1].y),PlaneVertices[2].y),PlaneVertices[3].y),b.y)-0.1;
 ShapeAABB.Min.z:=Min(Min(Min(Min(PlaneVertices[0].z,PlaneVertices[1].z),PlaneVertices[2].z),PlaneVertices[3].z),b.z)-0.1;
 ShapeAABB.Max.x:=Max(Max(Max(Max(PlaneVertices[0].x,PlaneVertices[1].x),PlaneVertices[2].x),PlaneVertices[3].x),b.x)+0.1;
 ShapeAABB.Max.y:=Max(Max(Max(Max(PlaneVertices[0].y,PlaneVertices[1].y),PlaneVertices[2].y),PlaneVertices[3].y),b.y)+0.1;
 ShapeAABB.Max.z:=Max(Max(Max(Max(PlaneVertices[0].z,PlaneVertices[1].z),PlaneVertices[2].z),PlaneVertices[3].z),b.z)+0.1;
end;

procedure TKraftShapePlane.CalculateMassData;
begin
end;

function TKraftShapePlane.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
var Index,BestIndex:longint;
    BestDistance,NewDistance:TKraftScalar;
    Normal:TKraftVector3;
begin
 Normal:=Vector3SafeNorm(Direction);
 BestDistance:=Vector3Dot(Normal,PlaneVertices[0]);
 BestIndex:=0;
 for Index:=1 to 3 do begin
  NewDistance:=Vector3Dot(Normal,PlaneVertices[Index]);
  if BestDistance<NewDistance then begin
   BestDistance:=NewDistance;
   BestIndex:=Index;
  end;
 end;
 result:=PlaneVertices[BestIndex];
 if Vector3Dot(Plane.Normal,Normal)<0.0 then begin
  result:=Vector3Sub(result,Vector3ScalarMul(Plane.Normal,PlaneSize));
 end;
end;

function TKraftShapePlane.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 if (Index>=0) and (Index<4) then begin
  result:=PlaneVertices[Index];
 end else begin
  result:=Vector3Origin;
 end;
end;

function TKraftShapePlane.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
var Index:longint;
    BestDistance,NewDistance:TKraftScalar;
    Normal:TKraftVector3;
begin
 result:=0;
 Normal:=Vector3SafeNorm(Direction);
 BestDistance:=Vector3Dot(Normal,PlaneVertices[0]);
 for Index:=1 to 3 do begin
  NewDistance:=Vector3Dot(Normal,PlaneVertices[Index]);
  if BestDistance<NewDistance then begin
   BestDistance:=NewDistance;
   result:=Index;
  end;
 end;
end;

function TKraftShapePlane.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=Vector3TermMatrixMul(PlaneCenter,Transform);
end;

function TKraftShapePlane.TestPoint(const p:TKraftVector3):boolean;
begin
 result:=false;
end;

function TKraftShapePlane.RayCast(var RayCastData:TKraftRaycastData):boolean;
var Origin,Direction:TKraftVector3;
    Time:TKraftScalar;
begin
 result:=false;
 Origin:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 Direction:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform));
 if Vector3LengthSquared(Direction)>EPSILON then begin
  Time:=-Vector3Dot(Plane.Normal,Direction);
  if abs(Time)>EPSILON then begin
   Time:=PlaneVectorDistance(Plane,Origin)/Time;
   if Time>=0.0 then begin
    if Time<RayCastData.MaxTime then begin
     RayCastData.TimeOfImpact:=Time;
     RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,Time)),WorldTransform);
     RayCastData.Normal:=Vector3TermMatrixMulBasis(Plane.Normal,WorldTransform);
     result:=true;
    end;
   end;
  end;
 end;
end;

{$ifdef DebugDraw}
procedure TKraftShapePlane.Draw(const CameraMatrix:TKraftMatrix4x4);
var ModelViewMatrix:TKraftMatrix4x4;
    n:TKraftVector3;
begin

 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  n:=Vector3NormEx(Vector3Cross(Vector3Sub(PlaneVertices[1],PlaneVertices[0]),Vector3Sub(PlaneVertices[2],PlaneVertices[0])));

{$ifdef UseDouble}
  glBegin(GL_TRIANGLES);
  glNormal3dv(@n);
  glVertex3dv(@PlaneVertices[0]);
  glVertex3dv(@PlaneVertices[1]);
  glVertex3dv(@PlaneVertices[2]);
  glVertex3dv(@PlaneVertices[2]);
  glVertex3dv(@PlaneVertices[3]);
  glVertex3dv(@PlaneVertices[0]);
  n:=Vector3Neg(n);
  glNormal3dv(@n);
  glVertex3dv(@PlaneVertices[2]);
  glVertex3dv(@PlaneVertices[1]);
  glVertex3dv(@PlaneVertices[0]);
  glVertex3dv(@PlaneVertices[0]);
  glVertex3dv(@PlaneVertices[3]);
  glVertex3dv(@PlaneVertices[2]);
  glEnd;
{$else}
  glBegin(GL_TRIANGLES);
  glNormal3fv(@n);
  glVertex3fv(@PlaneVertices[0]);
  glVertex3fv(@PlaneVertices[1]);
  glVertex3fv(@PlaneVertices[2]);
  glVertex3fv(@PlaneVertices[2]);
  glVertex3fv(@PlaneVertices[3]);
  glVertex3fv(@PlaneVertices[0]);
  n:=Vector3Neg(n);
  glNormal3fv(@n);
  glVertex3fv(@PlaneVertices[2]);
  glVertex3fv(@PlaneVertices[1]);
  glVertex3fv(@PlaneVertices[0]);
  glVertex3fv(@PlaneVertices[0]);
  glVertex3fv(@PlaneVertices[3]);
  glVertex3fv(@PlaneVertices[2]);
  glEnd;
{$endif}

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

constructor TKraftShapeTriangle.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AVertex0,AVertex1,AVertex2:TKraftVector3);
//var TriangleVertices:array[0..2] of TKraftVector3;
var Vertices:PPKraftConvexHullVertices;
begin

{TriangleVertices[0]:=AVertex0;
 TriangleVertices[1]:=AVertex1;
 TriangleVertices[2]:=AVertex2;

 ShapeConvexHull:=TKraftConvexHull.Create(APhysics);
 ShapeConvexHull.Load(pointer(@TriangleVertices[0]),length(TriangleVertices));
 ShapeConvexHull.Build;
 ShapeConvexHull.Finish;{}

 ShapeConvexHull:=TKraftConvexHull.Create(APhysics);

 ShapeConvexHull.CountVertices:=3;
 SetLength(ShapeConvexHull.Vertices,ShapeConvexHull.CountVertices);
 ShapeConvexHull.Vertices[0].Position:=AVertex0;
 ShapeConvexHull.Vertices[0].CountAdjacencies:=2;
 ShapeConvexHull.Vertices[0].Adjacencies[0]:=1;
 ShapeConvexHull.Vertices[0].Adjacencies[1]:=2;
 ShapeConvexHull.Vertices[1].Position:=AVertex1;
 ShapeConvexHull.Vertices[1].CountAdjacencies:=2;
 ShapeConvexHull.Vertices[1].Adjacencies[0]:=2;
 ShapeConvexHull.Vertices[1].Adjacencies[1]:=0;
 ShapeConvexHull.Vertices[2].Position:=AVertex2;
 ShapeConvexHull.Vertices[2].CountAdjacencies:=2;
 ShapeConvexHull.Vertices[2].Adjacencies[0]:=0;
 ShapeConvexHull.Vertices[2].Adjacencies[1]:=1;

 Vertices:=@ShapeConvexHull.Vertices[0];

 ShapeConvexHull.CountFaces:=2;
 SetLength(ShapeConvexHull.Faces,ShapeConvexHull.CountFaces);
 ShapeConvexHull.Faces[0].Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices^[1].Position,Vertices^[0].Position),Vector3Sub(Vertices^[2].Position,Vertices^[0].Position)));
 ShapeConvexHull.Faces[0].Plane.Distance:=-Vector3Dot(ShapeConvexHull.Faces[0].Plane.Normal,Vertices^[0].Position);
 ShapeConvexHull.Faces[0].CountVertices:=3;
 SetLength(ShapeConvexHull.Faces[0].Vertices,ShapeConvexHull.Faces[0].CountVertices);
 ShapeConvexHull.Faces[0].Vertices[0]:=0;
 ShapeConvexHull.Faces[0].Vertices[1]:=1;
 ShapeConvexHull.Faces[0].Vertices[2]:=2;
 ShapeConvexHull.Faces[0].EdgeVertexOffset:=0;
 ShapeConvexHull.Faces[1].Plane.Normal:=Vector3Neg(ShapeConvexHull.Faces[0].Plane.Normal);
 ShapeConvexHull.Faces[1].Plane.Distance:=-ShapeConvexHull.Faces[0].Plane.Distance;
 ShapeConvexHull.Faces[1].CountVertices:=3;
 SetLength(ShapeConvexHull.Faces[1].Vertices,ShapeConvexHull.Faces[1].CountVertices);
 ShapeConvexHull.Faces[1].Vertices[0]:=0;
 ShapeConvexHull.Faces[1].Vertices[1]:=2;
 ShapeConvexHull.Faces[1].Vertices[2]:=1;
 ShapeConvexHull.Faces[1].EdgeVertexOffset:=3;

 ShapeConvexHull.CountEdges:=3;
 SetLength(ShapeConvexHull.Edges,ShapeConvexHull.CountEdges);
 ShapeConvexHull.Edges[0].Vertices[0]:=2;
 ShapeConvexHull.Edges[0].Vertices[1]:=0;
 ShapeConvexHull.Edges[0].Faces[0]:=0;
 ShapeConvexHull.Edges[0].Faces[1]:=1;
 ShapeConvexHull.Edges[1].Vertices[0]:=1;
 ShapeConvexHull.Edges[1].Vertices[1]:=2;
 ShapeConvexHull.Edges[1].Faces[0]:=0;
 ShapeConvexHull.Edges[1].Faces[1]:=1;
 ShapeConvexHull.Edges[2].Vertices[0]:=0;
 ShapeConvexHull.Edges[2].Vertices[1]:=1;
 ShapeConvexHull.Edges[2].Faces[0]:=0;
 ShapeConvexHull.Edges[2].Faces[1]:=1;

 ShapeAABB.Min.x:=Min(Min(Vertices^[0].Position.x,Vertices^[1].Position.x),Vertices^[2].Position.x)-0.1;
 ShapeAABB.Min.y:=Min(Min(Vertices^[0].Position.y,Vertices^[1].Position.y),Vertices^[2].Position.y)-0.1;
 ShapeAABB.Min.z:=Min(Min(Vertices^[0].Position.z,Vertices^[1].Position.z),Vertices^[2].Position.z)-0.1;
 ShapeAABB.Max.x:=Max(Max(Vertices^[0].Position.x,Vertices^[1].Position.x),Vertices^[2].Position.x)+0.1;
 ShapeAABB.Max.y:=Max(Max(Vertices^[0].Position.y,Vertices^[1].Position.y),Vertices^[2].Position.y)+0.1;
 ShapeAABB.Max.z:=Max(Max(Vertices^[0].Position.z,Vertices^[1].Position.z),Vertices^[2].Position.z)+0.1;

 ShapeConvexHull.AABB:=ShapeAABB;

//ShapeSphere.Center:=Vector3Add(Vertices^[0].Position,Vector3Add(Vector3ScalarMul(Vector3Sub(Vertices^[1].Position,Vertices^[0].Position),0.5),Vector3ScalarMul(Vector3Sub(Vertices^[2].Position,Vertices^[0].Position),0.5)));
 ShapeSphere.Center.x:=(Vertices^[0].Position.x+Vertices^[1].Position.x+Vertices^[2].Position.x)/3.0;
 ShapeSphere.Center.y:=(Vertices^[0].Position.y+Vertices^[1].Position.y+Vertices^[2].Position.y)/3.0;
 ShapeSphere.Center.z:=(Vertices^[0].Position.z+Vertices^[1].Position.z+Vertices^[2].Position.z)/3.0;{}
 ShapeSphere.Radius:=sqrt(Max(Max(Vector3DistSquared(ShapeSphere.Center,Vertices^[0].Position),
                                  Vector3DistSquared(ShapeSphere.Center,Vertices^[1].Position)),
                                  Vector3DistSquared(ShapeSphere.Center,Vertices^[2].Position)));

 ShapeConvexHull.AngularMotionDisc:=Vector3Length(ShapeSphere.Center)+ShapeSphere.Radius;
 AngularMotionDisc:=ShapeConvexHull.AngularMotionDisc;

 inherited Create(APhysics,ARigidBody,ShapeConvexHull);

 ShapeType:=kstTriangle;

 FeatureRadius:=0.0;

end;

destructor TKraftShapeTriangle.Destroy;
begin
 ShapeConvexHull.Free;
 inherited Destroy;
end;

procedure TKraftShapeTriangle.UpdateShapeAABB;
var Vertices:PPKraftConvexHullVertices;
begin
 Vertices:=@ConvexHull.Vertices[0];
 ShapeAABB.Min.x:=Min(Min(Vertices^[0].Position.x,Vertices^[1].Position.x),Vertices^[2].Position.x)-0.1;
 ShapeAABB.Min.y:=Min(Min(Vertices^[0].Position.y,Vertices^[1].Position.y),Vertices^[2].Position.y)-0.1;
 ShapeAABB.Min.z:=Min(Min(Vertices^[0].Position.z,Vertices^[1].Position.z),Vertices^[2].Position.z)-0.1;
 ShapeAABB.Max.x:=Max(Max(Vertices^[0].Position.x,Vertices^[1].Position.x),Vertices^[2].Position.x)+0.1;
 ShapeAABB.Max.y:=Max(Max(Vertices^[0].Position.y,Vertices^[1].Position.y),Vertices^[2].Position.y)+0.1;
 ShapeAABB.Max.z:=Max(Max(Vertices^[0].Position.z,Vertices^[1].Position.z),Vertices^[2].Position.z)+0.1;
end;

procedure TKraftShapeTriangle.CalculateMassData;
begin
end;

procedure TKraftShapeTriangle.UpdateData;
const f1d3=1.0/3.0;
var Vertices:PPKraftConvexHullVertices;
begin
 Vertices:=@ConvexHull.Vertices[0];
//ShapeSphere.Center:=Vector3Add(Vertices^[0].Position,Vector3Add(Vector3ScalarMul(Vector3Sub(Vertices^[1].Position,Vertices^[0].Position),0.5),Vector3ScalarMul(Vector3Sub(Vertices^[2].Position,Vertices^[0].Position),0.5)));
 ShapeSphere.Center.x:=(Vertices^[0].Position.x+Vertices^[1].Position.x+Vertices^[2].Position.x)*f1d3;
 ShapeSphere.Center.y:=(Vertices^[0].Position.y+Vertices^[1].Position.y+Vertices^[2].Position.y)*f1d3;
 ShapeSphere.Center.z:=(Vertices^[0].Position.z+Vertices^[1].Position.z+Vertices^[2].Position.z)*f1d3;
 ShapeSphere.Radius:=sqrt(Max(Max(Vector3DistSquared(ShapeSphere.Center,Vertices^[0].Position),
                                  Vector3DistSquared(ShapeSphere.Center,Vertices^[1].Position)),
                                  Vector3DistSquared(ShapeSphere.Center,Vertices^[2].Position)));
 ShapeConvexHull.Faces[0].Plane.Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices^[1].Position,Vertices^[0].Position),Vector3Sub(Vertices^[2].Position,Vertices^[0].Position)));
 ShapeConvexHull.Faces[0].Plane.Distance:=-Vector3Dot(ShapeConvexHull.Faces[0].Plane.Normal,Vertices^[0].Position);
 ShapeConvexHull.Faces[1].Plane.Normal:=Vector3Neg(ShapeConvexHull.Faces[0].Plane.Normal);
 ShapeConvexHull.Faces[1].Plane.Distance:=-ShapeConvexHull.Faces[0].Plane.Distance;
 LocalCentroid:=ShapeSphere.Center;
 LocalCenterOfMass:=ShapeSphere.Center;
 AngularMotionDisc:=Vector3Length(ShapeSphere.Center)+ShapeSphere.Radius;
 FeatureRadius:=0.0;
end;

function TKraftShapeTriangle.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
var i:longint;
    Vertices:PPKraftConvexHullVertices;
    d0,d1,d2:TKraftScalar;
    Normal:TKraftVector3;
begin
 Vertices:=@ConvexHull.Vertices[0];
 Normal:=Vector3SafeNorm(Direction);
 d0:=Vector3Dot(Normal,Vertices^[0].Position);
 d1:=Vector3Dot(Normal,Vertices^[1].Position);
 d2:=Vector3Dot(Normal,Vertices^[2].Position);
 if d0>d1 then begin
  if d2>d0 then begin
   i:=2;
  end else begin
   i:=0;
  end;
 end else begin
  if d2>d1 then begin
   i:=2;
  end else begin
   i:=1;
  end;
 end;
 result:=Vertices^[i].Position;
end;

function TKraftShapeTriangle.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 if (Index>=0) and (Index<3) then begin
  result:=ConvexHull.Vertices[Index].Position;
 end else begin
  result:=Vector3Origin;
 end;
end;

function TKraftShapeTriangle.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
var Vertices:PPKraftConvexHullVertices;
    d0,d1,d2:TKraftScalar;
    Normal:TKraftVector3;
begin
 Vertices:=@ConvexHull.Vertices[0];
 Normal:=Vector3SafeNorm(Direction);
 d0:=Vector3Dot(Normal,Vertices^[0].Position);
 d1:=Vector3Dot(Normal,Vertices^[1].Position);
 d2:=Vector3Dot(Normal,Vertices^[2].Position);
 if d0>d1 then begin
  if d2>d0 then begin
   result:=2;
  end else begin
   result:=0;
  end;
 end else begin
  if d2>d1 then begin
   result:=2;
  end else begin
   result:=1;
  end;
 end;
end;

function TKraftShapeTriangle.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=Vector3TermMatrixMul(ShapeSphere.Center,Transform);
end;

function TKraftShapeTriangle.TestPoint(const p:TKraftVector3):boolean;
begin
 result:=false;
end;

function TKraftShapeTriangle.RayCast(var RayCastData:TKraftRaycastData):boolean;
var Origin,Direction:TKraftVector3;
    Vertices:PPKraftConvexHullVertices;
    Time,u,v:TKraftScalar;
begin
 result:=false;
 Origin:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 Direction:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform));
 if Vector3LengthSquared(Direction)>EPSILON then begin
  Vertices:=@ConvexHull.Vertices[0];
  if RayIntersectTriangle(Origin,Direction,Vertices^[0].Position,Vertices^[1].Position,Vertices^[2].Position,Time,u,v) then begin
   if (Time>=0.0) and (Time<=RayCastData.MaxTime) then begin
    RayCastData.TimeOfImpact:=Time;
    RayCastData.Point:=Vector3TermMatrixMul(Vector3Add(Origin,Vector3ScalarMul(Direction,Time)),WorldTransform);
    RayCastData.Normal:=Vector3TermMatrixMulBasis(Vector3NormEx(Vector3Cross(Vector3Sub(Vertices^[1].Position,Vertices^[0].Position),Vector3Sub(Vertices^[2].Position,Vertices^[0].Position))),WorldTransform);
    result:=true;
   end;
  end;
 end;
end;

{$ifdef DebugDraw}
procedure TKraftShapeTriangle.Draw(const CameraMatrix:TKraftMatrix4x4);
var ModelViewMatrix:TKraftMatrix4x4;
    Vertices:PPKraftConvexHullVertices;
    n:TKraftVector3;
begin

 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  Vertices:=@ConvexHull.Vertices[0];

  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  n:=Vector3NormEx(Vector3Cross(Vector3Sub(Vertices^[1].Position,Vertices^[0].Position),Vector3Sub(Vertices^[2].Position,Vertices^[0].Position)));

{$ifdef UseDouble}
  glBegin(GL_TRIANGLES);
  glNormal3dv(@n);
  glVertex3dv(@Vertices^[0].Position);
  glVertex3dv(@Vertices^[1].Position);
  glVertex3dv(@Vertices^[2].Position);
  n:=Vector3Neg(n);
  glNormal3dv(@n);
  glVertex3dv(@Vertices^[0].Position);
  glVertex3dv(@Vertices^[2].Position);
  glVertex3dv(@Vertices^[1].Position);
  glEnd;
{$else}
  glBegin(GL_TRIANGLES);
  glNormal3fv(@n);
  glVertex3fv(@Vertices^[0].Position);
  glVertex3fv(@Vertices^[1].Position);
  glVertex3fv(@Vertices^[2].Position);
  n:=Vector3Neg(n);
  glNormal3fv(@n);
  glVertex3fv(@Vertices^[0].Position);
  glVertex3fv(@Vertices^[2].Position);
  glVertex3fv(@Vertices^[1].Position);
  glEnd;
{$endif}

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

constructor TKraftShapeMesh.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AMesh:TKraftMesh);
begin

 Mesh:=AMesh;

 inherited Create(APhysics,ARigidBody);

 IsMesh:=true;

 ShapeType:=kstMesh;

 FeatureRadius:=0.0;

end;

destructor TKraftShapeMesh.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftShapeMesh.UpdateShapeAABB;
begin
 ShapeAABB:=Mesh.AABB;
end;

procedure TKraftShapeMesh.CalculateMassData;
begin
end;

function TKraftShapeMesh.GetLocalFullSupport(const Direction:TKraftVector3):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftShapeMesh.GetLocalFeatureSupportVertex(const Index:longint):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftShapeMesh.GetLocalFeatureSupportIndex(const Direction:TKraftVector3):longint;
begin
 result:=-1;
end;

function TKraftShapeMesh.GetCenter(const Transform:TKraftMatrix4x4):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftShapeMesh.TestPoint(const p:TKraftVector3):boolean;
begin
 result:=false;
end;

function TKraftShapeMesh.RayCast(var RayCastData:TKraftRaycastData):boolean;
var SkipListNodeIndex,TriangleIndex:longint;
    SkipListNode:PKraftMeshSkipListNode;
    Triangle:PKraftMeshTriangle;
    First:boolean;
    Nearest,Time,u,v:TKraftScalar;
    Origin,Direction,p,Normal:TKraftVector3;
begin
 result:=false;
 Origin:=Vector3TermMatrixMulInverted(RayCastData.Origin,WorldTransform);
 Direction:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(RayCastData.Direction,WorldTransform));
 if Vector3LengthSquared(Direction)>EPSILON then begin
  Nearest:=3.4e+38;
  First:=true;
  SkipListNodeIndex:=0;  
  while SkipListNodeIndex<Mesh.CountSkipListNodes do begin
   SkipListNode:=@Mesh.SkipListNodes[SkipListNodeIndex];
   if AABBRayIntersect(SkipListNode^.AABB,Origin,Direction) then begin
    TriangleIndex:=SkipListNode^.TriangleIndex;
    while TriangleIndex>=0 do begin
     Triangle:=@Mesh.Triangles[TriangleIndex];
     if RayIntersectTriangle(Origin,
                             Direction,
                             Mesh.Vertices[Triangle^.Vertices[0]],
                             Mesh.Vertices[Triangle^.Vertices[1]],
                             Mesh.Vertices[Triangle^.Vertices[2]],
                             Time,
                             u,
                             v) then begin
      p:=Vector3Add(Origin,Vector3ScalarMul(Direction,Time));
      if ((Time>=0.0) and (Time<=RayCastData.MaxTime)) and (First or (Time<Nearest)) then begin
       First:=false;
       Nearest:=Time;
       Normal:=Vector3Norm(Vector3Add(Vector3ScalarMul(Mesh.Normals[Triangle^.Normals[0]],1.0-(u+v)),
                           Vector3Add(Vector3ScalarMul(Mesh.Normals[Triangle^.Normals[1]],u),
                                      Vector3ScalarMul(Mesh.Normals[Triangle^.Normals[2]],v))));
       RayCastData.TimeOfImpact:=Time;
       RayCastData.Point:=p;
       RayCastData.Normal:=Normal;
       result:=true;
      end;
     end;
     TriangleIndex:=Triangle^.Next;
    end;
    inc(SkipListNodeIndex);
   end else begin
    SkipListNodeIndex:=SkipListNode^.SkipToNodeIndex;
   end;
  end;
  if result then begin
   RayCastData.Point:=Vector3TermMatrixMul(RayCastData.Point,WorldTransform);
   RayCastData.Normal:=Vector3NormEx(Vector3TermMatrixMulBasis(RayCastData.Normal,WorldTransform));
  end;
 end;
end;

{$ifdef DebugDraw}
procedure TKraftShapeMesh.Draw(const CameraMatrix:TKraftMatrix4x4);
var i:longint;
    ModelViewMatrix:TKraftMatrix4x4;
    Triangle:PKraftMeshTriangle;
begin
 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);
 ModelViewMatrix:=Matrix4x4TermMul(InterpolatedWorldTransform,CameraMatrix);
{$ifdef UseDouble}
 glLoadMatrixd(pointer(@ModelViewMatrix));
{$else}
 glLoadMatrixf(pointer(@ModelViewMatrix));
{$endif}

 if DrawDisplayList=0 then begin
  DrawDisplayList:=glGenLists(1);
  glNewList(DrawDisplayList,GL_COMPILE);

  glBegin(GL_TRIANGLES);
  for i:=0 to Mesh.CountTriangles-1 do begin
   Triangle:=@Mesh.Triangles[i];
{$ifdef UseDouble}
   glNormal3dv(@Mesh.Normals[Triangle^.Normals[0]]);
   glVertex3dv(@Mesh.Vertices[Triangle^.Vertices[0]]);
   glNormal3dv(@Mesh.Normals[Triangle^.Normals[1]]);
   glVertex3dv(@Mesh.Vertices[Triangle^.Vertices[1]]);
   glNormal3dv(@Mesh.Normals[Triangle^.Normals[2]]);
   glVertex3dv(@Mesh.Vertices[Triangle^.Vertices[2]]);
{$else}
   glNormal3fv(@Mesh.Normals[Triangle^.Normals[0]]);
   glVertex3fv(@Mesh.Vertices[Triangle^.Vertices[0]]);
   glNormal3fv(@Mesh.Normals[Triangle^.Normals[1]]);
   glVertex3fv(@Mesh.Vertices[Triangle^.Vertices[1]]);
   glNormal3fv(@Mesh.Normals[Triangle^.Normals[2]]);
   glVertex3fv(@Mesh.Vertices[Triangle^.Vertices[2]]);
{$endif}

  end;
  glEnd;

  glEndList;
 end;

 if DrawDisplayList<>0 then begin
  glCallList(DrawDisplayList);
 end;

 glPopMatrix;
end;
{$endif}

procedure TKraftContactPair.GetSolverContactManifold(out SolverContactManifold:TKraftSolverContactManifold;const WorldTransformA,WorldTransformB:TKraftMatrix4x4;PositionSolving:boolean);
var ContactIndex:longint;
    Contact:PKraftContact;
    SolverContact:PKraftSolverContact;
    PointA,PointB,PlanePoint,ClipPoint,cA,cB:TKraftVector3;
    tA,tB:TKraftMatrix4x4;
begin
 //PositionSolving:=true;
 tA:=Matrix4x4TermMul(Shapes[0].LocalTransform,WorldTransformA);
 tB:=Matrix4x4TermMul(Shapes[1].LocalTransform,WorldTransformB);
 SolverContactManifold.CountContacts:=Manifold.CountContacts;
 case Manifold.ContactManifoldType of
  kcmtImplicit:begin
   if Manifold.CountContacts>1 then begin
    SolverContactManifold.Normal:=Vector3Origin;
    for ContactIndex:=0 to Manifold.CountContacts-1 do begin
     Contact:=@Manifold.Contacts[ContactIndex];
     PointA:=Vector3TermMatrixMul(Contact^.LocalPoints[0],tA);
     PointB:=Vector3TermMatrixMul(Contact^.LocalPoints[1],tB);
     SolverContactManifold.Normal:=Vector3Add(SolverContactManifold.Normal,Vector3Sub(PointB,PointA));
    end;
    SolverContactManifold.Normal:=Vector3NormEx(SolverContactManifold.Normal);
    for ContactIndex:=0 to Manifold.CountContacts-1 do begin
     Contact:=@Manifold.Contacts[ContactIndex];
     SolverContact:=@SolverContactManifold.Contacts[ContactIndex];
     PointA:=Vector3TermMatrixMul(Contact^.LocalPoints[0],tA);
     PointB:=Vector3TermMatrixMul(Contact^.LocalPoints[1],tB);
     if PositionSolving then begin
      SolverContact^.Point:=Vector3Avg(PointA,PointB);
      SolverContact^.Separation:=Vector3Dot(Vector3Sub(PointB,PointA),SolverContactManifold.Normal)-(Manifold.LocalRadius[0]+Manifold.LocalRadius[1]);
     end else begin
      cA:=Vector3Add(PointA,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]));
      cB:=Vector3Sub(PointB,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]));
      SolverContact^.Point:=Vector3Avg(cA,cB);
      SolverContact^.Separation:=Vector3Dot(Vector3Sub(cB,cA),SolverContactManifold.Normal);
     end;
{    if abs(SolverContact^.Separation)>100.0 then begin
      if abs(SolverContact^.Separation)>100.0 then begin
       writeln(SolverContact^.Separation:1:8);
      end;
     end;}
    end;
   end else if Manifold.CountContacts=1 then begin
    Contact:=@Manifold.Contacts[0];
    SolverContact:=@SolverContactManifold.Contacts[0];
    PointA:=Vector3TermMatrixMul(Contact^.LocalPoints[0],tA);
    PointB:=Vector3TermMatrixMul(Contact^.LocalPoints[1],tB);
    SolverContactManifold.Normal:=Vector3NormEx(Vector3Sub(PointB,PointA));
    if PositionSolving then begin
     SolverContact^.Point:=Vector3Avg(PointA,PointB);
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(PointB,PointA),SolverContactManifold.Normal)-(Manifold.LocalRadius[0]+Manifold.LocalRadius[1]);
    end else begin
     cA:=Vector3Add(PointA,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]));
     cB:=Vector3Sub(PointB,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]));
     SolverContact^.Point:=Vector3Avg(cA,cB);
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(cB,cA),SolverContactManifold.Normal);
    end;
{   if abs(SolverContact^.Separation)>100.0 then begin
     if abs(SolverContact^.Separation)>100.0 then begin
      writeln(SolverContact^.Separation:1:8);
     end;
    end;}
   end;
  end;
  kcmtFaceA:begin
   SolverContactManifold.Normal:=Vector3TermMatrixMulBasis(Manifold.LocalNormal,tA);
   for ContactIndex:=0 to Manifold.CountContacts-1 do begin
    Contact:=@Manifold.Contacts[ContactIndex];
    SolverContact:=@SolverContactManifold.Contacts[ContactIndex];
    PlanePoint:=Vector3TermMatrixMul(Contact^.LocalPoints[0],tA);
    ClipPoint:=Vector3TermMatrixMul(Contact^.LocalPoints[1],tB);
    if PositionSolving then begin
     SolverContact^.Point:=ClipPoint;
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(ClipPoint,PlanePoint),SolverContactManifold.Normal)-(Manifold.LocalRadius[0]+Manifold.LocalRadius[1]);
    end else begin
     cA:=Vector3Add(ClipPoint,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]-Vector3Dot(Vector3Sub(ClipPoint,PlanePoint),SolverContactManifold.Normal)));
     cB:=Vector3Sub(ClipPoint,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]));
     SolverContact^.Point:=Vector3Avg(cA,cB);
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(cB,cA),SolverContactManifold.Normal);
    end;
   end;
  end;
  kcmtFaceB:begin
   SolverContactManifold.Normal:=Vector3TermMatrixMulBasis(Manifold.LocalNormal,tB);
   for ContactIndex:=0 to Manifold.CountContacts-1 do begin
    Contact:=@Manifold.Contacts[ContactIndex];
    SolverContact:=@SolverContactManifold.Contacts[ContactIndex];
    ClipPoint:=Vector3TermMatrixMul(Contact^.LocalPoints[0],tA);
    PlanePoint:=Vector3TermMatrixMul(Contact^.LocalPoints[1],tB);
    if PositionSolving then begin
     SolverContact^.Point:=ClipPoint;
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(ClipPoint,PlanePoint),SolverContactManifold.Normal)-(Manifold.LocalRadius[0]+Manifold.LocalRadius[1]);
    end else begin
     cA:=Vector3Sub(ClipPoint,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]));
     cB:=Vector3Add(ClipPoint,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]-Vector3Dot(Vector3Sub(ClipPoint,PlanePoint),SolverContactManifold.Normal)));
     SolverContact^.Point:=Vector3Avg(cA,cB);
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(cA,cB),SolverContactManifold.Normal);
    end;
   end;
   SolverContactManifold.Normal:=Vector3Neg(SolverContactManifold.Normal);
  end;
  kcmtEdges:begin
   if Manifold.CountContacts>0 then begin
    Contact:=@Manifold.Contacts[0];
    SolverContact:=@SolverContactManifold.Contacts[0];
    SolverContactManifold.Normal:=Vector3TermMatrixMulBasis(Manifold.LocalNormal,tA);
    cA:=Vector3Add(Vector3TermMatrixMul(Contact^.LocalPoints[0],tA),Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]));
    cB:=Vector3Sub(Vector3TermMatrixMul(Contact^.LocalPoints[1],tB),Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]));
    SolverContact^.Point:=Vector3Avg(cA,cB);
    SolverContact^.Separation:=Vector3Dot(Vector3Sub(cB,cA),SolverContactManifold.Normal);
   end;
  end;
  kcmtImplicitEdge:begin
   if Manifold.CountContacts>0 then begin
    Contact:=@Manifold.Contacts[0];
    SolverContact:=@SolverContactManifold.Contacts[0];
    SolverContactManifold.Normal:=Vector3TermMatrixMulBasis(Manifold.LocalNormal,tB);
    cA:=Vector3Add(Vector3TermMatrixMul(Contact^.LocalPoints[0],tA),Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]));
    cB:=Vector3Sub(Vector3TermMatrixMul(Contact^.LocalPoints[1],tB),Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]));
    SolverContact^.Point:=Vector3Avg(cA,cB);
    SolverContact^.Separation:=Vector3Dot(Vector3Sub(cB,cA),SolverContactManifold.Normal);
   end;
  end;
  kcmtImplicitNormal:begin
   SolverContactManifold.Normal:=Vector3TermMatrixMulBasis(Manifold.LocalNormal,tB);
   for ContactIndex:=0 to Manifold.CountContacts-1 do begin
    Contact:=@Manifold.Contacts[ContactIndex];
    SolverContact:=@SolverContactManifold.Contacts[ContactIndex];
    PointA:=Vector3TermMatrixMul(Contact^.LocalPoints[0],tA);
    PointB:=Vector3TermMatrixMul(Contact^.LocalPoints[1],tB);
    if PositionSolving then begin
     SolverContact^.Point:=Vector3Avg(PointA,PointB);
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(PointB,PointA),SolverContactManifold.Normal)-(Manifold.LocalRadius[0]+Manifold.LocalRadius[1]);
    end else begin
     cA:=Vector3Add(PointA,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[0]));
     cB:=Vector3Sub(PointB,Vector3ScalarMul(SolverContactManifold.Normal,Manifold.LocalRadius[1]));
     SolverContact^.Point:=Vector3Avg(cA,cB);
     SolverContact^.Separation:=Vector3Dot(Vector3Sub(cB,cA),SolverContactManifold.Normal);
    end;
   end;
  end;
 end;
end;

procedure TKraftContactPair.DetectCollisions(const ContactManager:TKraftContactManager;const TriangleShape:TKraftShape=nil;const ThreadIndex:longint=0);
var OldManifoldCountContacts:longint;
    ShapeTriangle:TKraftShapeTriangle;
 procedure AddImplicitContact(const p0,p1:TKraftVector3;const r0,r1:TKraftScalar;const Key:longword;const IsLocal:boolean); {$ifdef caninline}inline;{$endif}
 var Contact:PKraftContact;
 begin
  if Manifold.CountContacts<MAX_CONTACTS then begin
   Manifold.ContactManifoldType:=kcmtImplicit;
   Manifold.LocalRadius[0]:=r0;
   Manifold.LocalRadius[1]:=r1;
   Contact:=@Manifold.Contacts[Manifold.CountContacts];
   inc(Manifold.CountContacts);
   if IsLocal then begin
    Contact^.LocalPoints[0]:=p0;
    Contact^.LocalPoints[1]:=p1;
   end else begin
    Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(p0,Shapes[0].WorldTransform);
    Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(p1,Shapes[1].WorldTransform);
   end;
   Contact^.FeaturePair.Key:=Key;
  end;
 end;
 procedure AddFaceAContact(const Normal,p0,p1:TKraftVector3;const r0,r1:TKraftScalar;const Key:longword;const IsLocal:boolean); {$ifdef caninline}inline;{$endif}
 var Contact:PKraftContact;
 begin
  if Manifold.CountContacts<MAX_CONTACTS then begin
   Manifold.ContactManifoldType:=kcmtFaceA;
   Manifold.LocalNormal:=Normal;
   Manifold.LocalRadius[0]:=r0;
   Manifold.LocalRadius[1]:=r1;
   Contact:=@Manifold.Contacts[Manifold.CountContacts];
   inc(Manifold.CountContacts);
   if IsLocal then begin
    Contact^.LocalPoints[0]:=p0;
    Contact^.LocalPoints[1]:=p1;
   end else begin
    Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(p0,Shapes[0].WorldTransform);
    Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(p1,Shapes[1].WorldTransform);
   end;
   Contact^.FeaturePair.Key:=Key;
  end;
 end;
 procedure AddFaceBContact(const Normal,p0,p1:TKraftVector3;const r0,r1:TKraftScalar;const Key:longword;const IsLocal:boolean); {$ifdef caninline}inline;{$endif}
 var Contact:PKraftContact;
 begin
  if Manifold.CountContacts<MAX_CONTACTS then begin
   Manifold.ContactManifoldType:=kcmtFaceB;
   Manifold.LocalNormal:=Normal;
   Manifold.LocalRadius[0]:=r0;
   Manifold.LocalRadius[1]:=r1;
   Contact:=@Manifold.Contacts[Manifold.CountContacts];
   inc(Manifold.CountContacts);
   if IsLocal then begin
    Contact^.LocalPoints[0]:=p0;
    Contact^.LocalPoints[1]:=p1;
   end else begin
    Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(p0,Shapes[0].WorldTransform);
    Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(p1,Shapes[1].WorldTransform);
   end;
   Contact^.FeaturePair.Key:=Key;
  end;
 end;
 procedure AddImplicitEdgeContact(const Normal,p0,p1:TKraftVector3;const r0,r1:TKraftScalar;const Key:longword;const IsLocal:boolean); {$ifdef caninline}inline;{$endif}
 var Contact:PKraftContact;
 begin
  if Manifold.CountContacts<MAX_CONTACTS then begin
   Manifold.ContactManifoldType:=kcmtImplicitEdge;
   Manifold.LocalNormal:=Normal;
   Manifold.LocalRadius[0]:=r0;
   Manifold.LocalRadius[1]:=r1;
   Contact:=@Manifold.Contacts[Manifold.CountContacts];
   inc(Manifold.CountContacts);
   if IsLocal then begin
    Contact^.LocalPoints[0]:=p0;
    Contact^.LocalPoints[1]:=p1;
   end else begin
    Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(p0,Shapes[0].WorldTransform);
    Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(p1,Shapes[1].WorldTransform);
   end;
   Contact^.FeaturePair.Key:=Key;
  end;
 end;
 procedure AddImplicitNormalContact(const Normal,p0,p1:TKraftVector3;const r0,r1:TKraftScalar;const Key:longword;const IsLocal:boolean); {$ifdef caninline}inline;{$endif}
 var Contact:PKraftContact;
 begin
  if Manifold.CountContacts<MAX_CONTACTS then begin
   Manifold.ContactManifoldType:=kcmtImplicitNormal;
   Manifold.LocalNormal:=Normal;
   Manifold.LocalRadius[0]:=r0;
   Manifold.LocalRadius[1]:=r1;
   Contact:=@Manifold.Contacts[Manifold.CountContacts];
   inc(Manifold.CountContacts);
   if IsLocal then begin
    Contact^.LocalPoints[0]:=p0;
    Contact^.LocalPoints[1]:=p1;
   end else begin
    Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(p0,Shapes[0].WorldTransform);
    Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(p1,Shapes[1].WorldTransform);
   end;
   Contact^.FeaturePair.Key:=Key;
  end;
 end;
 procedure CollideSphereWithSphere(ShapeA,ShapeB:TKraftShapeSphere); {$ifdef caninline}inline;{$endif}
 var Distance:TKraftScalar;
     CenterA,CenterB:TKraftVector3;
 begin
  CenterA:=Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform);
  CenterB:=Vector3TermMatrixMul(ShapeB.LocalCentroid,ShapeB.WorldTransform);
  Distance:=Vector3Length(Vector3Sub(CenterB,CenterA));
  if Distance<(ShapeA.Radius+ShapeB.Radius) then begin
   if Distance<EPSILON then begin
    // Degenerate case
    AddImplicitNormalContact(Vector3XAxis,ShapeA.LocalCentroid,ShapeB.LocalCentroid,ShapeA.Radius,ShapeB.Radius,1,true);
   end else begin
    // Normal case
    AddImplicitContact(ShapeA.LocalCentroid,ShapeB.LocalCentroid,ShapeA.Radius,ShapeB.Radius,1,true);
   end;
  end;
 end;
 procedure CollideSphereWithCapsule(ShapeA:TKraftShapeSphere;ShapeB:TKraftShapeCapsule); {$ifdef caninline}inline;{$endif}
 var Alpha,HalfLength,Distance:TKraftScalar;
     CenterA,CenterB,Position,GeometryDirection:TKraftVector3;
 begin
  GeometryDirection:=PKraftVector3(pointer(@ShapeB.WorldTransform[1,0]))^;
  CenterA:=Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform);
  CenterB:=Vector3TermMatrixMul(ShapeB.LocalCentroid,ShapeB.WorldTransform);
  Alpha:=(GeometryDirection.x*(CenterA.x-CenterB.x))+(GeometryDirection.y*(Centera.y-CenterB.y))+(GeometryDirection.z*(CenterA.z-CenterB.z));
  HalfLength:=ShapeB.Height*0.5;
  if Alpha>HalfLength then begin
   Alpha:=HalfLength;
  end else if alpha<-HalfLength then begin
   Alpha:=-HalfLength;
  end;
  Position:=Vector3Add(CenterB,Vector3ScalarMul(GeometryDirection,Alpha));
  Distance:=Vector3DistSquared(Position,CenterA);
  if Distance<=sqr(ShapeA.Radius+ShapeB.Radius) then begin
   if Distance<EPSILON then begin
    // Degenerate case
    AddImplicitNormalContact(Vector3XAxis,CenterA,Position,ShapeA.Radius,ShapeB.Radius,1,false);
   end else begin
    // Normal case
    AddImplicitContact(CenterA,Position,ShapeA.Radius,ShapeB.Radius,1,false);
   end;
  end;
 end;
 procedure CollideSphereWithConvexHull(ShapeA:TKraftShapeSphere;ShapeB:TKraftShapeConvexHull); {$ifdef caninline}inline;{$endif}
 var FaceIndex,ClosestFaceIndex,VertexIndex:longint;
     Distance,ClosestDistance,BestClosestPointDistance,d:TKraftScalar;
     Center,SphereCenter,Normal,ClosestPoint,BestClosestPointOnHull,BestClosestPointNormal,ab,ap,a,b,v,n:TKraftVector3;
     InsideSphere,InsidePolygon,HasBestClosestPoint:boolean;
     Face:PKraftConvexHullFace;
     GJK:TKraftGJK;
 begin

  GJK.CachedSimplex:=nil;
  GJK.Simplex.Count:=0;
  GJK.Shapes[0]:=ShapeA;
  GJK.Shapes[1]:=ShapeB;
  GJK.Transforms[0]:=@ShapeA.WorldTransform;
  GJK.Transforms[1]:=@ShapeB.WorldTransform;
  GJK.UseRadii:=false;

  GJK.Run;

  if (GJK.Distance>0.0) and not GJK.Failed then begin

   // Shallow contact, the more simple way

   if GJK.Distance<=ShapeA.Radius then begin
    AddImplicitNormalContact(Vector3Neg(Vector3TermMatrixMulTransposedBasis(GJK.Normal,Shapes[1].WorldTransform)),
                             GJK.ClosestPoints[0],
                             GJK.ClosestPoints[1],
                             ShapeA.Radius,
                             0.0,
                             1,
                             false);
   end;

  end else begin

   // Deep contact, the more hard way, the followed code works also for shallow contacts, but GJK should be faster for shallow
   // contacts, I think.  

   BestClosestPointDistance:=3.4e+38;
   HasBestClosestPoint:=false;
   ClosestDistance:=3.4e+38;
   ClosestFaceIndex:=-1;
   InsideSphere:=true;
   Center:=Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform);
   SphereCenter:=Vector3TermMatrixMulInverted(Center,ShapeB.WorldTransform);
   for FaceIndex:=0 to ShapeB.ConvexHull.CountFaces-1 do begin
    Face:=@ShapeB.ConvexHull.Faces[FaceIndex];
    Distance:=PlaneVectorDistance(Face^.Plane,SphereCenter);
    if Distance>0.0 then begin
     // sphere center is not inside in the convex hull . . .
     if Distance<ShapeA.Radius then begin
      // but touching . . .
      if Face^.CountVertices>0 then begin
       InsidePolygon:=true;
       n:=Face^.Plane.Normal;
       b:=ShapeB.ConvexHull.Vertices[Face^.Vertices[Face^.CountVertices-1]].Position;
       for VertexIndex:=0 to Face^.CountVertices-1 do begin
        a:=b;
        b:=ShapeB.ConvexHull.Vertices[Face^.Vertices[VertexIndex]].Position;
        ab:=Vector3Sub(b,a);
        ap:=Vector3Sub(SphereCenter,a);
        v:=Vector3Cross(ab,n);
        if Vector3Dot(ap,v)>0.0 then begin
         d:=Vector3LengthSquared(ab);
         if d<>0.0 then begin
          d:=Vector3Dot(ab,ap)/d;
         end else begin
          d:=0.0;
         end;
         ClosestPoint:=Vector3Lerp(a,b,d);
         InsidePolygon:=false;
         break;
        end;
       end;
       if InsidePolygon then begin
        // sphere is directly touching the convex hull . . .
        AddFaceBContact(n,
                        Center,
                        Vector3TermMatrixMul(Vector3Sub(SphereCenter,Vector3ScalarMul(n,Distance)),ShapeB.WorldTransform),
                        ShapeA.Radius,
                        0.0,
                        1,
                        false);
        exit;
       end else begin
        // the sphere may not be directly touching the polyhedron, but it may be touching a point or an edge, if the distance between
        // the closest point on the poly and the center of the sphere is less than the sphere radius we have a hit.
        Normal:=Vector3Sub(SphereCenter,ClosestPoint);
        if Vector3LengthSquared(Normal)<sqr(ShapeA.Radius) then begin
         Distance:=Vector3LengthNormalize(Normal);
         if (not HasBestClosestPoint) or (BestClosestPointDistance>Distance) then begin
          HasBestClosestPoint:=true;
          BestClosestPointDistance:=Distance;
          BestClosestPointOnHull:=ClosestPoint;
          BestClosestPointNormal:=Normal;
         end;
        end;
       end;
      end;
     end;
     InsideSphere:=false;
    end else if InsideSphere and ((ClosestFaceIndex<0) or (ClosestDistance>abs(Distance))) then begin
     ClosestDistance:=abs(Distance);
     ClosestFaceIndex:=FaceIndex;
    end;
   end;
   if InsideSphere and (ClosestFaceIndex>=0) then begin
    // the sphere center is inside the convex hull . . .
    n:=ShapeB.ConvexHull.Faces[ClosestFaceIndex].Plane.Normal;
    AddImplicitNormalContact(n,
                             Center,
                             Vector3TermMatrixMul(Vector3Add(SphereCenter,Vector3ScalarMul(n,-ClosestDistance)),ShapeB.WorldTransform),
                             ShapeA.Radius,
                             0.0,
                             1,
                             false);
   end else if HasBestClosestPoint then begin
    AddImplicitNormalContact(Vector3Neg(BestClosestPointNormal),
                             Center,
                             Vector3TermMatrixMul(BestClosestPointOnHull,ShapeB.WorldTransform),
                             ShapeA.Radius,
                             0.0,
                             1,
                             false);
   end;
  end;
 end;
 procedure CollideSphereWithBox(ShapeA:TKraftShapeSphere;ShapeB:TKraftShapeBox); {$ifdef caninline}inline;{$endif}
 const ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
 var IntersectionDist,ContactDist,DistSqr,FaceDist,MinDist:TKraftScalar;
     Center,SphereRelativePosition,ClosestPoint,Normal:TKraftVector3;
     Axis,AxisSign:longint;
 begin
  Center:=Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform);
  SphereRelativePosition:=Vector3TermMatrixMulInverted(Center,ShapeB.WorldTransform);
  ClosestPoint.x:=Min(Max(SphereRelativePosition.x,-ShapeB.Extents.x),ShapeB.Extents.x);
  ClosestPoint.y:=Min(Max(SphereRelativePosition.y,-ShapeB.Extents.y),ShapeB.Extents.y);
  ClosestPoint.z:=Min(Max(SphereRelativePosition.z,-ShapeB.Extents.z),ShapeB.Extents.z);
  Normal:=Vector3Sub(SphereRelativePosition,ClosestPoint);
  DistSqr:=Vector3LengthSquared(Normal);
  IntersectionDist:=ShapeA.Radius;
  ContactDist:=IntersectionDist+EPSILON;
  if DistSqr<=sqr(ContactDist) then begin
   if DistSqr<=EPSILON then begin
    begin
     FaceDist:=ShapeB.Extents.x-SphereRelativePosition.x;
     MinDist:=FaceDist;
     Axis:=0;
     AxisSign:=1;
    end;
    begin
     FaceDist:=ShapeB.Extents.x+SphereRelativePosition.x;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=0;
      AxisSign:=-1;
     end;
    end;
    begin
     FaceDist:=ShapeB.Extents.y-SphereRelativePosition.y;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=1;
      AxisSign:=1;
     end;
    end;
    begin
     FaceDist:=ShapeB.Extents.y+SphereRelativePosition.y;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=1;
      AxisSign:=-1;
     end;
    end;
    begin
     FaceDist:=ShapeB.Extents.z-SphereRelativePosition.z;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=2;
      AxisSign:=1;
     end;
    end;
    begin
     FaceDist:=ShapeB.Extents.z+SphereRelativePosition.z;
     if FaceDist<MinDist then begin
//    MinDist:=FaceDist;
      Axis:=2;
      AxisSign:=-1;
     end;
    end;
    ClosestPoint:=SphereRelativePosition;
    ClosestPoint.xyz[Axis]:=ShapeB.Extents.xyz[Axis]*AxisSign;
    Normal:=Vector3Origin;
    Normal.xyz[Axis]:=AxisSign;
//  Distance:=-MinDist;
   end else begin
    {Distance:=}Vector3NormalizeEx(Normal);
   end;
   AddFaceBContact(Normal,Center,Vector3TermMatrixMul(ClosestPoint,ShapeB.WorldTransform),ShapeA.Radius,0.0,1,false);
  end;
 end;
 procedure CollideSphereWithPlane(ShapeA:TKraftShapeSphere;ShapeB:TKraftShapePlane); {$ifdef caninline}inline;{$endif}
 var Distance:TKraftScalar;
     Center,SphereCenter,Normal:TKraftVector3;
 begin
  Center:=Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform);
  SphereCenter:=Vector3TermMatrixMulInverted(Center,ShapeB.WorldTransform);
  Distance:=PlaneVectorDistance(ShapeB.Plane,SphereCenter);
  if Distance<=ShapeA.Radius then begin
   Normal:=ShapeB.Plane.Normal;
   AddFaceBContact(Normal,Center,Vector3TermMatrixMul(Vector3Sub(SphereCenter,Vector3ScalarMul(Normal,Distance)),ShapeB.WorldTransform),ShapeA.Radius,0.0,1,false);
  end;
 end;
 procedure CollideSphereWithTriangle(ShapeA:TKraftShapeSphere;ShapeB:TKraftShapeTriangle); {$ifdef caninline}inline;{$endif}
 const ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
 var i:longint;
     Radius,RadiusWithThreshold,DistanceFromPlane,ContactRadiusSqr,DistanceSqr:TKraftScalar;
     Center,SphereCenter,Normal,P0ToCenter,ContactPointOnTriangle,NearestOnEdge,ContactToCenter:TKraftVector3;
     IsInsideContactPlane,HasContact,IsEdge:boolean;
     v:array[0..2] of PKraftVector3;
 begin
  v[0]:=@ShapeB.ConvexHull.Vertices[0].Position;
  v[1]:=@ShapeB.ConvexHull.Vertices[1].Position;
  v[2]:=@ShapeB.ConvexHull.Vertices[2].Position;
  Center:=Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform);
  SphereCenter:=Vector3TermMatrixMulInverted(Center,ShapeB.WorldTransform);
  Radius:=ShapeA.Radius;
  RadiusWithThreshold:=Radius+EPSILON;
  Normal:=Vector3SafeNorm(Vector3Cross(Vector3Sub(v[1]^,v[0]^),Vector3Sub(v[2]^,v[0]^)));
  P0ToCenter:=Vector3Sub(SphereCenter,v[0]^);
  DistanceFromPlane:=Vector3Dot(P0ToCenter,Normal);
  if DistanceFromPlane<0.0 then begin
   DistanceFromPlane:=-DistanceFromPlane;
   Normal:=Vector3Neg(Normal);
  end;
  IsInsideContactPlane:=DistanceFromPlane<RadiusWithThreshold;
  HasContact:=false;
  IsEdge:=false;
  ContactPointOnTriangle:=Vector3Origin;
  ContactRadiusSqr:=sqr(RadiusWithThreshold);
  if IsInsideContactPlane then begin
   if PointInTriangle(v[0]^,v[1]^,v[2]^,Normal,SphereCenter) then begin
    HasContact:=true;
    ContactPointOnTriangle:=Vector3Sub(SphereCenter,Vector3ScalarMul(Normal,DistanceFromPlane));
   end else begin
    for i:=0 to 2 do begin
     DistanceSqr:=SegmentSqrDistance(v[i]^,v[ModuloThree[i+1]]^,SphereCenter,NearestOnEdge);
     if DistanceSqr<ContactRadiusSqr then begin
      HasContact:=true;
      IsEdge:=true;
      ContactPointOnTriangle:=NearestOnEdge;
     end;
    end;
   end;
  end;
  if IsEdge then begin
  end;
  if HasContact then begin
   ContactToCenter:=Vector3Sub(SphereCenter,ContactPointOnTriangle);
   DistanceSqr:=Vector3LengthSquared(ContactToCenter);
   if DistanceSqr<ContactRadiusSqr then begin
    if DistanceSqr>EPSILON then begin
    {if IsEdge then begin
      AddImplicitNormalContact(Vector3Neg(ContactToCenter),Center,Vector3TermMatrixMul(ContactPointOnTriangle,ShapeB.WorldTransform),ShapeA.Radius,0.0,1);
     end else}begin
      AddImplicitContact(Center,Vector3TermMatrixMul(ContactPointOnTriangle,ShapeB.WorldTransform),ShapeA.Radius,0.0,1,false);
     end;
    end else begin
     AddFaceBContact(Normal,Center,Vector3TermMatrixMul(ContactPointOnTriangle,ShapeB.WorldTransform),ShapeA.Radius,0.0,1,false);
    end;
   end;
  end;
 end;
 procedure CollideCapsuleWithCapsule(ShapeA,ShapeB:TKraftShapeCapsule); {$ifdef caninline}inline;{$endif}
 const Tolerance=0.005;
 var RadiusA,RadiusB,SquaredRadiiWithTolerance,HalfLengthA,HalfLengthB,TimeA,TimeB,SquaredDistance:TKraftScalar;
     CenterA,CenterB,GeometryDirectionA,GeometryDirectionB,HalfAxis,ClosestPointA,ClosestPointB:TKraftVector3;
     SegmentA,SegmentB:TKraftSegment;
 begin

  CenterA:=Vector3TermMatrixMul(ShapeA.LocalCenterOfMass,ShapeA.WorldTransform);
  CenterB:=Vector3TermMatrixMul(ShapeB.LocalCenterOfMass,ShapeB.WorldTransform);

  GeometryDirectionA:=PKraftVector3(pointer(@ShapeA.WorldTransform[1,0]))^;
  GeometryDirectionB:=PKraftVector3(pointer(@ShapeB.WorldTransform[1,0]))^;

  RadiusA:=ShapeA.Radius;
  RadiusB:=ShapeB.Radius;

  SquaredRadiiWithTolerance:=sqr((RadiusA+RadiusB)+EPSILON);

  HalfLengthA:=ShapeA.Height*0.5;
  HalfLengthB:=ShapeB.Height*0.5;

  HalfAxis:=Vector3ScalarMul(GeometryDirectionA,HalfLengthA);
  SegmentA.Points[0]:=Vector3Sub(CenterA,HalfAxis);
  SegmentA.Points[1]:=Vector3Add(CenterA,HalfAxis);

  HalfAxis:=Vector3ScalarMul(GeometryDirectionB,HalfLengthB);
  SegmentB.Points[0]:=Vector3Sub(CenterB,HalfAxis);
  SegmentB.Points[1]:=Vector3Add(CenterB,HalfAxis);

  // Find the closest points between the two capsules
  SIMDSegmentClosestPoints(SegmentA,SegmentB,TimeA,ClosestPointA,TimeB,ClosestPointB);

  SquaredDistance:=Vector3DistSquared(ClosestPointA,ClosestPointB);

  if SquaredDistance<SquaredRadiiWithTolerance then begin

   if SquaredDistance<EPSILON then begin
    // Degenerate case
    AddImplicitNormalContact(Vector3XAxis,
                             ClosestPointA,
                             ClosestPointB,
                             RadiusA,
                             RadiusB,
                             1,
                             false);
   end else begin
    // Normal case
    AddImplicitContact(ClosestPointA,
                       ClosestPointB,
                       RadiusA,
                       RadiusB,
                       1,
                       false);
   end;

   // If the two capsules are nearly parallel, an additional support point provides stability
   {if (Vector3Length(Vector3Cross(GeometryDirectionA,GeometryDirectionB))<(sqrt(Vector3LengthSquared(GeometryDirectionA)*Vector3LengthSquared(GeometryDirectionB))*Tolerance)) then{}begin

    if abs(TimeA)<EPSILON then begin
     ClosestPointA:=SegmentA.Points[1];
     SIMDSegmentClosestPointTo(SegmentB,ClosestPointA,TimeB,ClosestPointB);
    end else if abs(1.0-TimeA)<EPSILON then begin
     ClosestPointA:=SegmentA.Points[0];
     SIMDSegmentClosestPointTo(SegmentB,ClosestPointA,TimeB,ClosestPointB);
    end else if abs(TimeB)<EPSILON then begin
     ClosestPointB:=SegmentB.Points[1];
     SIMDSegmentClosestPointTo(SegmentA,ClosestPointB,TimeA,ClosestPointA);
    end else if abs(1.0-TimeB)<EPSILON then begin
     ClosestPointB:=SegmentB.Points[0];
     SIMDSegmentClosestPointTo(SegmentA,ClosestPointB,TimeA,ClosestPointA);
    end else begin
     exit;
    end;

    SquaredDistance:=Vector3DistSquared(ClosestPointA,ClosestPointB);
    if SquaredDistance<SquaredRadiiWithTolerance then begin
     if SquaredDistance<EPSILON then begin
      // Degenerate case
      AddImplicitNormalContact(Vector3XAxis,
                               ClosestPointA,
                               ClosestPointB,
                               RadiusA,
                               RadiusB,
                               2,
                               false);
     end else begin
      // Normal case
      AddImplicitContact(ClosestPointA,
                         ClosestPointB,
                         RadiusA,
                         RadiusB,
                         2,
                         false);
     end;
    end;
   end;

  end;


 end;
 procedure CollideCapsuleWithConvexHull(ShapeA:TKraftShapeCapsule;ShapeB:TKraftShapeConvexHull); {$ifdef caninline}inline;{$endif}
 const Tolerance=0.005;
 var FaceIndex,VertexIndex,OtherVertexIndex,PointIndex,MaxFaceIndex,MaxEdgeIndex,EdgeIndex:longint;
     CapsuleRadius,Distance,MaxFaceSeparation,MaxEdgeSeparation,Separation,L:TKraftScalar;
     CapsulePosition,CapsuleAxis,CapsulePointStart,CapsulePointEnd,Normal,FaceNormal,MaxFaceSeparateAxis,
     MaxEdgeSeparateAxis,CenterB,Ea,Eb,Ea_x_Eb:TKraftVector3;
     OK:boolean;
     Face:PKraftConvexHullFace;
     Edge:PKraftConvexHullEdge;
     Plane:TKraftPlane;
     ClosestPoints:array[0..1] of TKraftVector3;
     GJK:TKraftGJK;
     Transform:TKraftMatrix4x4;
  function GetEdgeContact(var CA,CB:TKraftVector3;const PA,QA,PB,QB:TKraftVector3):boolean;
  var DA,DB,r:TKraftVector3;
      a,e,f,c,b,d,TA,TB:TKraftScalar;
  begin
   DA:=Vector3Sub(QA,PA);
   DB:=Vector3Sub(QB,PB);
   r:=Vector3Sub(PA,PB);
	 a:=Vector3LengthSquared(DA);
	 e:=Vector3LengthSquared(DB);
	 f:=Vector3Dot(DB,r);
	 c:=Vector3Dot(DA,r);
   b:=Vector3Dot(DA,DB);
   d:=(a*e)-sqr(b);
   if (d<>0.0) and (e<>0.0) then begin
    TA:=Min(Max(((b*f)-(c*e))/d,0.0),1.0);
    TB:=Min(Max(((b*TA)+f)/e,0.0),1.0);
    CA:=Vector3Add(PA,Vector3ScalarMul(DA,TA));
    CB:=Vector3Add(PB,Vector3ScalarMul(DB,TB));
    result:=true;
   end else begin
    result:=false;
   end;
  end;
 begin

  Manifold.CountContacts:=0;

  GJK.CachedSimplex:=nil;
  GJK.Simplex.Count:=0;
  GJK.Shapes[0]:=ShapeA;
  GJK.Shapes[1]:=ShapeB;
  GJK.Transforms[0]:=@ShapeA.WorldTransform;
  GJK.Transforms[1]:=@ShapeB.WorldTransform;
  GJK.UseRadii:=false;

  GJK.Run;
                                
  if (GJK.Distance>0.0) and not GJK.Failed then begin

   // Shallow contact

   if GJK.Distance<=ShapeA.Radius then begin

    // Check for a parallel face first
    Normal:=GJK.Normal;
    for FaceIndex:=0 to ShapeB.ConvexHull.CountFaces-1 do begin
     Face:=@ShapeB.ConvexHull.Faces[FaceIndex];
     FaceNormal:=Vector3Norm(Vector3TermMatrixMulBasis(Face^.Plane.Normal,ShapeB.WorldTransform));
     if (Vector3Dot(FaceNormal,Normal)>0.0) and
        (Vector3Length(Vector3Cross(FaceNormal,Normal))<(sqrt(Vector3LengthSquared(FaceNormal)*Vector3LengthSquared(Normal))*Tolerance)) then begin
      CapsulePosition:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform),ShapeB.WorldTransform);
      CapsuleAxis:=Vector3Norm(Vector3TermMatrixMulTransposedBasis(Vector3(ShapeA.WorldTransform[1,0],ShapeA.WorldTransform[1,1],ShapeA.WorldTransform[1,2]),ShapeB.WorldTransform));
      ClosestPoints[0]:=Vector3Sub(CapsulePosition,Vector3ScalarMul(CapsuleAxis,ShapeA.Height*0.5));
      ClosestPoints[1]:=Vector3Add(CapsulePosition,Vector3ScalarMul(CapsuleAxis,ShapeA.Height*0.5));
      if Face^.CountVertices>0 then begin
       OK:=true;
       OtherVertexIndex:=Face^.CountVertices-1;
       for VertexIndex:=0 to Face^.CountVertices-1 do begin
        Plane.Normal:=Vector3Norm(Vector3Cross(Face^.Plane.Normal,Vector3Sub(ShapeB.ConvexHull.Vertices[Face^.Vertices[VertexIndex]].Position,ShapeB.ConvexHull.Vertices[Face^.Vertices[OtherVertexIndex]].Position)));
        Plane.Distance:=-Vector3Dot(Plane.Normal,ShapeB.ConvexHull.Vertices[Face^.Vertices[VertexIndex]].Position);
        if not ClipSegmentToPlane(Plane,ClosestPoints[0],ClosestPoints[1]) then begin
         OK:=false;
         break;
        end;
        OtherVertexIndex:=VertexIndex;
       end;
       if OK then begin
        for PointIndex:=0 to 1 do begin
         Distance:=PlaneVectorDistance(Face^.Plane,ClosestPoints[PointIndex]);
         if Distance<=ShapeA.Radius then begin
          FaceNormal:=Face^.Plane.Normal;
          AddFaceBContact(FaceNormal,
                          Vector3TermMatrixMul(ClosestPoints[PointIndex],ShapeB.WorldTransform),
                          Vector3TermMatrixMul(Vector3Sub(ClosestPoints[PointIndex],Vector3ScalarMul(FaceNormal,Distance)),ShapeB.WorldTransform),
                          ShapeA.Radius,
                          0.0,
                          PointIndex+1,
                          false);
         end;
        end;
        if Manifold.CountContacts>1 then begin
         exit;
        end else begin
         Manifold.CountContacts:=0;
        end;
       end;
      end;
     end;
    end;

    // No parallel face plane with two contacts found, so use GJK closest points for one TKraftScalar implicit surface contact
    AddImplicitNormalContact(Vector3Neg(Vector3TermMatrixMulTransposedBasis(GJK.Normal,Shapes[1].WorldTransform)),
                             GJK.ClosestPoints[0],
                             GJK.ClosestPoints[1],
                             ShapeA.Radius,
                             0.0,
                             1,
                             false);
   end;

  end else begin

   // Deep contact

   CapsuleRadius:=ShapeA.Radius;

   CapsulePosition:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform),ShapeB.WorldTransform);
   CapsuleAxis:=Vector3Norm(Vector3TermMatrixMulTransposedBasis(Vector3(ShapeA.WorldTransform[1,0],ShapeA.WorldTransform[1,1],ShapeA.WorldTransform[1,2]),ShapeB.WorldTransform));

   CapsulePointStart:=Vector3Sub(CapsulePosition,Vector3ScalarMul(CapsuleAxis,ShapeA.Height*0.5));
   CapsulePointEnd:=Vector3Add(CapsulePosition,Vector3ScalarMul(CapsuleAxis,ShapeA.Height*0.5));

   Transform:=Matrix4x4TermMulInverted(ShapeB.WorldTransform,ShapeA.WorldTransform);
   MaxFaceIndex:=-1;
   MaxFaceSeparation:=-3.4e+38;
   for FaceIndex:=0 to ShapeB.ConvexHull.CountFaces-1 do begin
    Face:=@ShapeB.ConvexHull.Faces[FaceIndex];
    Plane:=PlaneFastTransform(Face^.Plane,Transform);
    Separation:=PlaneVectorDistance(Plane,ShapeA.GetLocalFullSupport(Vector3Neg(Plane.Normal)));
    if Separation>0.0 then begin
     exit;
    end else if MaxFaceSeparation<Separation then begin
     MaxFaceIndex:=FaceIndex;
     MaxFaceSeparation:=Separation;
     MaxFaceSeparateAxis:=Face^.Plane.Normal;
    end;
   end;

   MaxEdgeIndex:=-1;
   MaxEdgeSeparation:=-3.4e+38;
   Ea:=Vector3Sub(CapsulePointEnd,CapsulePointStart);
   CenterB:=ShapeB.LocalCenterOfMass;
   for EdgeIndex:=0 to ShapeB.ConvexHull.CountEdges-1 do begin
    Edge:=@ShapeB.ConvexHull.Edges[EdgeIndex];
    if (Vector3Dot(Ea,ShapeB.ConvexHull.Faces[Edge^.Faces[0]].Plane.Normal)*Vector3Dot(Ea,ShapeB.ConvexHull.Faces[Edge^.Faces[1]].Plane.Normal))<0.0 then begin

     Eb:=Vector3Sub(ShapeB.ConvexHull.Vertices[Edge^.Vertices[1]].Position,ShapeB.ConvexHull.Vertices[Edge^.Vertices[0]].Position);

     // Build search direction
     Ea_x_Eb:=Vector3Cross(Ea,Eb);

     // Skip near parallel edges: |Ea x Eb| = sin(alpha) * |Ea| * |Eb|
     L:=Vector3Length(Ea_x_Eb);
     if L<(sqrt(Vector3LengthSquared(Ea)*Vector3LengthSquared(Eb))*Tolerance) then begin
      continue;
     end;

     // Assure consistent normal orientation (here: HullA -> HullB)
     Normal:=Vector3ScalarMul(Ea_x_Eb,1.0/L);
     if Vector3Dot(Normal,Vector3Sub(ShapeB.ConvexHull.Vertices[Edge^.Vertices[0]].Position,CenterB))<0.0 then begin
      Normal:=Vector3Neg(Normal);
     end;

     Separation:=Vector3Dot(Normal,Vector3Sub(CapsulePointStart,ShapeB.ConvexHull.Vertices[Edge^.Vertices[0]].Position))-CapsuleRadius;
     if Separation>0.0 then begin
      exit;
     end else if MaxEdgeSeparation<Separation then begin
      MaxEdgeSeparation:=Separation;
      MaxEdgeSeparateAxis:=Normal;
      MaxEdgeIndex:=EdgeIndex;
     end;
    end;

   end;
         
   if (MaxEdgeIndex>=0) and (MaxEdgeSeparation>(MaxFaceSeparation+0.05)) then begin
    Edge:=@ShapeB.ConvexHull.Edges[MaxEdgeIndex];
    if GetEdgeContact(ClosestPoints[0],
                      ClosestPoints[1],
                      CapsulePointStart,
                      CapsulePointEnd,
                      ShapeB.ConvexHull.Vertices[Edge^.Vertices[0]].Position,
                      ShapeB.ConvexHull.Vertices[Edge^.Vertices[1]].Position) then begin
     AddImplicitEdgeContact(Vector3Neg(MaxEdgeSeparateAxis),
                            ClosestPoints[0],
                            ClosestPoints[1],
                            CapsuleRadius,
                            0.0,
                            1,
                            false);
     exit;
    end;
   end;            

   if MaxFaceIndex>=0 then begin
    ClosestPoints[0]:=CapsulePointStart;
    ClosestPoints[1]:=CapsulePointEnd;
    Face:=@ShapeB.ConvexHull.Faces[MaxFaceIndex];
    if Face^.CountVertices>0 then begin
     OK:=true;
     OtherVertexIndex:=Face^.CountVertices-1;
     for VertexIndex:=0 to Face^.CountVertices-1 do begin
      Plane.Normal:=Vector3Norm(Vector3Cross(Face^.Plane.Normal,Vector3Sub(ShapeB.ConvexHull.Vertices[Face^.Vertices[VertexIndex]].Position,ShapeB.ConvexHull.Vertices[Face^.Vertices[OtherVertexIndex]].Position)));
      Plane.Distance:=-Vector3Dot(Plane.Normal,ShapeB.ConvexHull.Vertices[Face^.Vertices[VertexIndex]].Position);
      if not ClipSegmentToPlane(Plane,ClosestPoints[0],ClosestPoints[1]) then begin
       OK:=false;
       break;
      end;
      OtherVertexIndex:=VertexIndex;
     end;
     if OK then begin
      FaceNormal:=Face^.Plane.Normal;
      for PointIndex:=0 to 1 do begin
       Distance:=PlaneVectorDistance(Face^.Plane,ClosestPoints[PointIndex]);
       if Distance<=ShapeA.Radius then begin
        AddFaceBContact(FaceNormal,
                        Vector3TermMatrixMul(ClosestPoints[PointIndex],ShapeB.WorldTransform),
                        Vector3TermMatrixMul(Vector3Sub(ClosestPoints[PointIndex],Vector3ScalarMul(FaceNormal,Distance)),ShapeB.WorldTransform),
                        CapsuleRadius,
                        0.0,
                        PointIndex+1,
                        false);
       end;
      end;
     end;
    end;
   end;
  end;

 end;
 procedure CollideCapsuleWithTriangle(ShapeA:TKraftShapeCapsule;ShapeB:TKraftShapeTriangle); {$ifdef caninline}inline;{$endif}
 var Index,Count:longint;
     Radius,HalfLength,SquaredDistance,SquaredRadius,d:TKraftScalar;
     Center,GeometryDirection,HalfAxis,pa,pb,Normal:TKraftVector3;
     Segment:TKraftSegment;
     Triangle:TKraftTriangle;
     UseTriangleNormal:boolean;
 begin

  Manifold.CountContacts:=0;

  Center:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(ShapeA.LocalCentroid,ShapeA.WorldTransform),ShapeB.WorldTransform);

  GeometryDirection:=Vector3TermMatrixMulTransposedBasis(PKraftVector3(pointer(@ShapeA.WorldTransform[1,0]))^,ShapeB.WorldTransform);

  Triangle.Points[0]:=ShapeB.ConvexHull.Vertices[0].Position;
  Triangle.Points[1]:=ShapeB.ConvexHull.Vertices[1].Position;
  Triangle.Points[2]:=ShapeB.ConvexHull.Vertices[2].Position;
  Triangle.Normal:=ShapeB.ConvexHull.Faces[0].Plane.Normal;

  Radius:=ShapeA.Radius;

  SquaredRadius:=sqr(Radius);

  HalfLength:=ShapeA.Height*0.5;

  HalfAxis:=Vector3ScalarMul(GeometryDirection,HalfLength);
  Segment.Points[0]:=Vector3Sub(Center,HalfAxis);
  Segment.Points[1]:=Vector3Add(Center,HalfAxis);

  Count:=0;
  for Index:=0 to 1 do begin
   pa:=Segment.Points[Index];
   UseTriangleNormal:=SIMDTriangleClosestPointTo(Triangle,pa,pb);
   SquaredDistance:=Vector3DistSquared(pa,pb);
   if SquaredDistance<(SquaredRadius+EPSILON) then begin
    if UseTriangleNormal then begin
     Normal:=Triangle.Normal;
    end else begin
     Normal:=Vector3Sub(pa,pb);
     d:=Vector3Dot(Normal,Triangle.Normal);
     if d<-EPSILON then begin
      Normal:=Vector3Sub(pa,Vector3ScalarMul(Triangle.Normal,2.0*d));
     end;
     Vector3NormalizeEx(Normal);
    end;
    Normal:=Vector3TermMatrixMulBasis(Normal,ShapeB.WorldTransform);
    AddFaceBContact(Normal,
                    Vector3TermMatrixMul(pa,ShapeB.WorldTransform),
                    Vector3TermMatrixMul(pb,ShapeB.WorldTransform),
                    Radius,
                    0.0,
                    Index+1,
                    false);
    inc(Count);
   end;
  end;

  if Count<2 then begin

   UseTriangleNormal:=SIMDTriangleClosestPointTo(Triangle,Segment,d,pa,pb);
   SquaredDistance:=Vector3DistSquared(pa,pb);
   if ((d>=EPSILON) and (d<=(1.0-EPSILON))) and (SquaredDistance<(SquaredRadius+EPSILON)) then begin
    if UseTriangleNormal then begin
     Normal:=Triangle.Normal;
    end else begin
     Normal:=Vector3Sub(pa,pb);
     d:=Vector3Dot(Normal,Triangle.Normal);
     if d<-EPSILON then begin
      Normal:=Vector3Sub(pa,Vector3ScalarMul(Triangle.Normal,2.0*d));
     end;
     Vector3NormalizeEx(Normal);
    end;
    Normal:=Vector3TermMatrixMulBasis(Normal,ShapeB.WorldTransform);
    AddFaceBContact(Normal,
                    Vector3TermMatrixMul(pa,ShapeB.WorldTransform),
                    Vector3TermMatrixMul(pb,ShapeB.WorldTransform),
                    Radius,
                    0.0,
                    3,
                    false);
   end;

  end;

 end;
 procedure CollideConvexHullWithConvexHull(ShapeA,ShapeB:TKraftShapeConvexHull);
 const kTolerance=0.005; // Skip near parallel edges: |Ea x Eb| = sin(alpha) * |Ea| * |Eb|
       eTolerance=0.05;
  function IsMinkowskiFace(const A,B,B_x_A,C,D,D_x_C:TKraftVector3):boolean; {$ifdef caninline}inline;{$endif}
  var CBA,DBA,ADC,BDC:TKraftScalar;
  begin
   // Test if arcs AB and CD intersect on the unit sphere
   CBA:=Vector3Dot(C,B_x_A);
   DBA:=Vector3Dot(D,B_x_A);
   ADC:=Vector3Dot(A,D_x_C);
   BDC:=Vector3Dot(B,D_x_C);
   result:=((CBA*DBA<0.0)) and ((ADC*BDC)<0.0) and ((CBA*BDC)>0.0);
  end;
  function TestEarlyFaceDirection(const HullA,HullB:TKraftShapeConvexHull;var FaceQuery:TKraftContactFaceQuery):boolean; {$ifdef caninline}inline;{$endif}
  var Plane:TKraftPlane;
      Transform:TKraftMatrix4x4;
  begin
   Transform:=Matrix4x4TermMulSimpleInverted(HullA.WorldTransform,HullB.WorldTransform);
   Plane:=PlaneFastTransform(HullA.ConvexHull.Faces[FaceQuery.Index].Plane,Transform);
   FaceQuery.Separation:=PlaneVectorDistance(Plane,HullB.GetLocalFullSupport(Vector3Neg(Plane.Normal)));
   result:=FaceQuery.Separation>0.0;
  end;
  function TestEarlyEdgeDirection(const HullA,HullB:TKraftShapeConvexHull;var EdgeQuery:TKraftContactEdgeQuery):boolean; {$ifdef caninline}inline;{$endif}
  var EdgeA,EdgeB:PKraftConvexHullEdge;
      L:TKraftScalar;
      CenterA,Pa,Qa,Ea,Ua,Va,Pb,Qb,Eb,Ub,Vb,Ea_x_Eb,Normal:TKraftVector3;
      Transform:TKraftMatrix4x4;
  begin
   result:=false;
   Transform:=Matrix4x4TermMulSimpleInverted(HullA.WorldTransform,HullB.WorldTransform);
   CenterA:=HullA.GetCenter(Transform);
   EdgeA:=@HullA.ConvexHull.Edges[EdgeQuery.IndexA];
   Pa:=Vector3TermMatrixMul(HullA.ConvexHull.Vertices[EdgeA^.Vertices[0]].Position,Transform);
   Qa:=Vector3TermMatrixMul(HullA.ConvexHull.Vertices[EdgeA^.Vertices[1]].Position,Transform);
   Ea:=Vector3Sub(Qa,Pa);
   Ua:=Vector3Norm(Vector3TermMatrixMulBasis(HullA.ConvexHull.Faces[EdgeA^.Faces[0]].Plane.Normal,Transform));
   Va:=Vector3Norm(Vector3TermMatrixMulBasis(HullA.ConvexHull.Faces[EdgeA^.Faces[1]].Plane.Normal,Transform));
   EdgeB:=@HullB.ConvexHull.Edges[EdgeQuery.IndexB];
   Pb:=HullB.ConvexHull.Vertices[EdgeB^.Vertices[0]].Position;
   Qb:=HullB.ConvexHull.Vertices[EdgeB^.Vertices[1]].Position;
   Eb:=Vector3Sub(Qb,Pb);
   Ub:=HullB.ConvexHull.Faces[EdgeB^.Faces[0]].Plane.Normal;
   Vb:=HullB.ConvexHull.Faces[EdgeB^.Faces[1]].Plane.Normal;
   if IsMinkowskiFace(Ua,Va,Vector3Neg(Ea),Vector3Neg(Ub),Vector3Neg(Vb),Vector3Neg(Eb)) then begin
    // Build search direction
    Ea_x_Eb:=Vector3Cross(Ea,Eb);

    // Skip near parallel edges: |Ea x Eb| = sin(alpha) * |Ea| * |Eb|
    L:=Vector3Length(Ea_x_Eb);
    if L<(sqrt(Vector3LengthSquared(Ea)*Vector3LengthSquared(Eb))*kTolerance) then begin
     result:=false;
     exit;
    end;

    // Assure consistent normal orientation (here: HullA -> HullB)
    Normal:=Vector3ScalarMul(Ea_x_Eb,1.0/L);
    if Vector3Dot(Normal,Vector3Sub(Pa,CenterA))<0.0 then begin
     Normal:=Vector3Neg(Normal);
    end;

    // s = Dot(Normal, Pb) - d = Dot(Normal, Pb) - Dot(Normal, Pa) = Dot(Normal, Pb - Pa)
    EdgeQuery.Separation:=Vector3Dot(Normal,Vector3Sub(Pb,Pa));
    if EdgeQuery.Separation>0.0 then begin
     EdgeQuery.Normal:=Normal;
     result:=true;
    end;

   end;
  end;
  procedure QueryFaceDirections(const HullA,HullB:TKraftShapeConvexHull;out OutFaceQuery:TKraftContactFaceQuery); {$ifdef caninline}inline;{$endif}
  var MaxIndex,Index:longint;
      MaxSeparation,Separation:TKraftScalar;
      Plane:TKraftPlane;
      Transform:TKraftMatrix4x4;
  begin
   Transform:=Matrix4x4TermMulSimpleInverted(HullA.WorldTransform,HullB.WorldTransform);
   MaxIndex:=-1;
   MaxSeparation:=-3.4e+38;
   for Index:=0 to HullA.ConvexHull.CountFaces-1 do begin
    Plane:=PlaneFastTransform(HullA.ConvexHull.Faces[Index].Plane,Transform);
    Separation:=PlaneVectorDistance(Plane,HullB.GetLocalFullSupport(Vector3Neg(Plane.Normal)));
    if (Index=0) or (MaxSeparation<Separation) then begin
     MaxSeparation:=Separation;
     MaxIndex:=Index;
     if MaxSeparation>0.0 then begin
      break;
     end;
    end;
   end;
   OutFaceQuery.Index:=MaxIndex;
   OutFaceQuery.Separation:=MaxSeparation;
  end;
  procedure QueryEdgeDirections(const HullA,HullB:TKraftShapeConvexHull;out OutEdgeQuery:TKraftContactEdgeQuery); {$ifdef caninline}inline;{$endif}
  var EdgeA,EdgeB:PKraftConvexHullEdge;
      IndexA,IndexB,MaxIndexA,MaxIndexB:longint;
      MaxSeparation,Separation,L:TKraftScalar;
      CenterA,Pa,Qa,Ea,Ua,Va,Pb,Qb,Eb,Ub,Vb,Ea_x_Eb,Normal,MaxNormal:TKraftVector3;
      Transform:TKraftMatrix4x4;
      First:boolean;
  begin
   MaxIndexA:=-1;
   MaxIndexB:=-1;
   MaxSeparation:=-3.4e+38;
   MaxNormal:=Vector3Origin;
   Transform:=Matrix4x4TermMulSimpleInverted(HullA.WorldTransform,HullB.WorldTransform);
   CenterA:=HullA.GetCenter(Transform);
   First:=true;
   for IndexA:=0 to HullA.ConvexHull.CountEdges-1 do begin
    EdgeA:=@HullA.ConvexHull.Edges[IndexA];
    Pa:=Vector3TermMatrixMul(HullA.ConvexHull.Vertices[EdgeA^.Vertices[0]].Position,Transform);
    Qa:=Vector3TermMatrixMul(HullA.ConvexHull.Vertices[EdgeA^.Vertices[1]].Position,Transform);
    Ea:=Vector3Sub(Qa,Pa);
    Ua:=Vector3Norm(Vector3TermMatrixMulBasis(HullA.ConvexHull.Faces[EdgeA^.Faces[0]].Plane.Normal,Transform));
    Va:=Vector3Norm(Vector3TermMatrixMulBasis(HullA.ConvexHull.Faces[EdgeA^.Faces[1]].Plane.Normal,Transform));
    for IndexB:=0 to HullB.ConvexHull.CountEdges-1 do begin
     EdgeB:=@HullB.ConvexHull.Edges[IndexB];
     Pb:=HullB.ConvexHull.Vertices[EdgeB^.Vertices[0]].Position;
     Qb:=HullB.ConvexHull.Vertices[EdgeB^.Vertices[1]].Position;
     Eb:=Vector3Sub(Qb,Pb);
     Ub:=HullB.ConvexHull.Faces[EdgeB^.Faces[0]].Plane.Normal;
     Vb:=HullB.ConvexHull.Faces[EdgeB^.Faces[1]].Plane.Normal;
     if IsMinkowskiFace(Ua,Va,Vector3Neg(Ea),Vector3Neg(Ub),Vector3Neg(Vb),Vector3Neg(Eb)) then begin
      // Build search direction
      Ea_x_Eb:=Vector3Cross(Ea,Eb);

      // Skip near parallel edges: |Ea x Eb| = sin(alpha) * |Ea| * |Eb|
      L:=Vector3Length(Ea_x_Eb);
      if L<(sqrt(Vector3LengthSquared(Ea)*Vector3LengthSquared(Eb))*kTolerance) then begin
       continue;
      end;

      // Assure consistent normal orientation (here: HullA -> HullB)
      Normal:=Vector3ScalarMul(Ea_x_Eb,1.0/L);
      if Vector3Dot(Normal,Vector3Sub(Pa,CenterA))<0.0 then begin
       Normal:=Vector3Neg(Normal);
      end;

      // s = Dot(Normal, Pb) - d = Dot(Normal, Pb) - Dot(Normal, Pa) = Dot(Normal, Pb - Pa)
      Separation:=Vector3Dot(Normal,Vector3Sub(Pb,Pa));
      if First or (MaxSeparation<Separation) then begin
       First:=false;
       MaxSeparation:=Separation;
       MaxIndexA:=IndexA;
       MaxIndexB:=IndexB;
       MaxNormal:=Normal;
       if MaxSeparation>0.0 then begin
        break;
       end;
      end;

     end;
    end;
   end;
   OutEdgeQuery.IndexA:=MaxIndexA;
   OutEdgeQuery.IndexB:=MaxIndexB;
   OutEdgeQuery.Separation:=MaxSeparation;
   OutEdgeQuery.Normal:=MaxNormal;
  end;
  function GetEdgeContact(var CA,CB:TKraftVector3;const PA,QA,PB,QB:TKraftVector3):boolean; {$ifdef caninline}inline;{$endif}
  var DA,DB,r:TKraftVector3;
      a,e,f,c,b,d,TA,TB:TKraftScalar;
  begin
   DA:=Vector3Sub(QA,PA);
   DB:=Vector3Sub(QB,PB);
   r:=Vector3Sub(PA,PB);
	 a:=Vector3LengthSquared(DA);
	 e:=Vector3LengthSquared(DB);
	 f:=Vector3Dot(DB,r);
	 c:=Vector3Dot(DA,r);
   b:=Vector3Dot(DA,DB);
   d:=(a*e)-sqr(b);
   if (d<>0.0) and (e<>0.0) then begin
    TA:=Min(Max(((b*f)-(c*e))/d,0.0),1.0);
    TB:=Min(Max(((b*TA)+f)/e,0.0),1.0);
    CA:=Vector3Add(PA,Vector3ScalarMul(DA,TA));
    CB:=Vector3Add(PB,Vector3ScalarMul(DB,TB));
    result:=true;
   end else begin
    result:=false;
   end;
  end;
  function FindIncidentFaceIndex(const ReferenceHull:TKraftShapeConvexHull;const ReferenceFaceIndex:longint;const IncidentHull:TKraftShapeConvexHull):longint; {$ifdef caninline}inline;{$endif}
  var i:longint;
      MinDot,Dot:TKraftScalar;
      ReferenceNormal:TKraftVector3;
  begin
   ReferenceNormal:=Vector3TermMatrixMulTransposedBasis(Vector3TermMatrixMulBasis(ReferenceHull.ConvexHull.Faces[ReferenceFaceIndex].Plane.Normal,
                                                                        ReferenceHull.WorldTransform),
                                                        IncidentHull.WorldTransform);
   result:=-1;
   MinDot:=3.4e+38;
   for i:=0 to IncidentHull.ConvexHull.CountFaces-1 do begin
    Dot:=Vector3Dot(ReferenceNormal,IncidentHull.ConvexHull.Faces[i].Plane.Normal);
		if MinDot>Dot then begin
		 MinDot:=Dot;
     result:=i;
    end;
   end;
  end;
  procedure ClipFaceContactPoints(const ReferenceHull:TKraftShapeConvexHull;const ReferenceFaceIndex:longint;const IncidentHull:TKraftShapeConvexHull;const IncidentFaceIndex:longint;const Flip:boolean);
  var Contact:PKraftContact;
      ReferenceVertexIndex,OtherReferenceVertexIndex,IncidentVertexIndex,ClipVertexIndex:longint;
      ReferenceFace,IncidentFace:PKraftConvexHullFace;
      ClipVertex,FirstClipVertex,EndClipVertex:PKraftVector3;
      StartDistance,EndDistance,Distance:TKraftScalar;
      ClipVertices:array[0..2] of TKraftConvexHullVertexList;
      ReferencePoint:TKraftVector3;
      ReferenceWorldPlane,ReferenceEdgePlane:TKraftPlane;
  begin

   ContactManager.CountTemporaryContacts[ThreadIndex]:=0;

   ReferenceFace:=@ReferenceHull.ConvexHull.Faces[ReferenceFaceIndex];
   ReferenceWorldPlane:=PlaneFastTransform(ReferenceFace^.Plane,ReferenceHull.WorldTransform);

   IncidentFace:=@IncidentHull.ConvexHull.Faces[IncidentFaceIndex];

   ClipVertices[0]:=ContactManager.ConvexHullVertexLists[ThreadIndex,0];
   ClipVertices[0].Clear;

   for IncidentVertexIndex:=0 to IncidentFace^.CountVertices-1 do begin
    ClipVertices[0].Add(Vector3TermMatrixMul(IncidentHull.ConvexHull.Vertices[IncidentFace^.Vertices[IncidentVertexIndex]].Position,IncidentHull.WorldTransform));
   end;

{$ifdef DebugDraw}
    if (ContactManager.Physics.CountThreads<2) and (ContactManager.CountDebugConvexHullVertexLists<length(ContactManager.DebugConvexHullVertexLists)) then begin
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.r:=0.5;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.g:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.b:=0.5;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.a:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Clear;
     for ClipVertexIndex:=0 to ClipVertices[0].Count-1 do begin
      ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Add(ClipVertices[0].Vertices[ClipVertexIndex]);
     end;
     inc(ContactManager.CountDebugConvexHullVertexLists);
    end;
    if (ContactManager.Physics.CountThreads<2) and (ContactManager.CountDebugConvexHullVertexLists<length(ContactManager.DebugConvexHullVertexLists)) then begin
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.r:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.g:=0.5;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.b:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.a:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Clear;
     for ReferenceVertexIndex:=0 to ReferenceFace^.CountVertices-1 do begin
      ReferencePoint:=Vector3TermMatrixMul(ReferenceHull.ConvexHull.Vertices[ReferenceFace^.Vertices[ReferenceVertexIndex]].Position,ReferenceHull.WorldTransform);
      ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Add(ReferencePoint);
     end;
     inc(ContactManager.CountDebugConvexHullVertexLists);
    end;
{$endif}

   ClipVertices[1]:=ContactManager.ConvexHullVertexLists[ThreadIndex,1];
   ClipVertices[1].Clear;

   OtherReferenceVertexIndex:=ReferenceFace^.CountVertices-1;
   for ReferenceVertexIndex:=0 to ReferenceFace^.CountVertices-1 do begin
    if ClipVertices[0].Count>=2 then begin
     ReferencePoint:=Vector3TermMatrixMul(ReferenceHull.ConvexHull.Vertices[ReferenceFace^.Vertices[ReferenceVertexIndex]].Position,ReferenceHull.WorldTransform);
     ReferenceEdgePlane.Normal:=Vector3Neg(Vector3NormEx(Vector3Cross(ReferenceWorldPlane.Normal,Vector3Sub(ReferencePoint,Vector3TermMatrixMul(ReferenceHull.ConvexHull.Vertices[ReferenceFace^.Vertices[OtherReferenceVertexIndex]].Position,ReferenceHull.WorldTransform)))));
     ReferenceEdgePlane.Distance:=-Vector3Dot(ReferenceEdgePlane.Normal,ReferencePoint);
     FirstClipVertex:=@ClipVertices[0].Vertices[ClipVertices[0].Count-1];
     EndClipVertex:=@ClipVertices[0].Vertices[0];
     StartDistance:=PlaneVectorDistance(ReferenceEdgePlane,FirstClipVertex^);
     for ClipVertexIndex:=0 to ClipVertices[0].Count-1 do begin
      EndClipVertex:=@ClipVertices[0].Vertices[ClipVertexIndex];
      EndDistance:=PlaneVectorDistance(ReferenceEdgePlane,EndClipVertex^);
      if StartDistance<0.0 then begin
       if EndDistance<0.0 then begin
        ClipVertices[1].Add(EndClipVertex^);
       end else begin
        ClipVertices[1].Add(Vector3Lerp(FirstClipVertex^,EndClipVertex^,StartDistance/(StartDistance-EndDistance)));
       end;
      end else if EndDistance<0.0 then begin
       ClipVertices[1].Add(Vector3Lerp(FirstClipVertex^,EndClipVertex^,StartDistance/(StartDistance-EndDistance)));
       ClipVertices[1].Add(EndClipVertex^);
      end;
      FirstClipVertex:=EndClipVertex;
      StartDistance:=EndDistance;
     end;
    end;
    if ClipVertices[1].Count=0 then begin
     exit;
    end else begin
     ClipVertices[2]:=ClipVertices[0];
     ClipVertices[0]:=ClipVertices[1];
     ClipVertices[1]:=ClipVertices[2];
     ClipVertices[1].Clear;
     OtherReferenceVertexIndex:=ReferenceVertexIndex;
    end;
   end;

{$ifdef DebugDraw}
    if (ContactManager.Physics.CountThreads<2) and (ContactManager.CountDebugConvexHullVertexLists<length(ContactManager.DebugConvexHullVertexLists)) then begin
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.r:=0.5;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.g:=0.5;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.b:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Color.a:=1.0;
     ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Clear;
     for ClipVertexIndex:=0 to ClipVertices[0].Count-1 do begin
      ContactManager.DebugConvexHullVertexLists[ContactManager.CountDebugConvexHullVertexLists].Add(ClipVertices[0].Vertices[ClipVertexIndex]);
     end;
     inc(ContactManager.CountDebugConvexHullVertexLists);
    end;
{$endif}

   for ClipVertexIndex:=0 to ClipVertices[0].Count-1 do begin
    ClipVertex:=@ClipVertices[0].Vertices[ClipVertexIndex];
    Distance:=PlaneVectorDistance(ReferenceWorldPlane,ClipVertex^);
    if Distance<0.0 then begin
     if ContactManager.CountTemporaryContacts[ThreadIndex]<MAX_TEMPORARY_CONTACTS then begin
      Contact:=@ContactManager.TemporaryContacts[ThreadIndex,ContactManager.CountTemporaryContacts[ThreadIndex]];
      inc(ContactManager.CountTemporaryContacts[ThreadIndex]);
      if Flip then begin
       Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(ClipVertex^,Shapes[0].WorldTransform);
       Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(Vector3Add(ClipVertex^,Vector3ScalarMul(ReferenceWorldPlane.Normal,-Distance)),Shapes[1].WorldTransform);
      end else begin
       Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(Vector3Add(ClipVertex^,Vector3ScalarMul(ReferenceWorldPlane.Normal,-Distance)),Shapes[0].WorldTransform);
       Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(ClipVertex^,Shapes[1].WorldTransform);
      end;
      Contact^.Penetration:=Distance;
      Contact^.FeaturePair.Key:=$ffffffff;// ClipVertexIndex; // $ffffffff => nearest current-frame=>last-frame contact point search for warm starting
     end else begin
      break;
     end;
    end;
   end;

  end;
 var Contact:PKraftContact;
     Iteration,ReferenceFaceIndex,IncidentFaceIndex:longint;
     EdgeA,EdgeB:PKraftConvexHullEdge;
     PenetrationDepth:TKraftScalar;
     a0,a1,b0,b1,pa,pb,Normal:TKraftVector3;
 begin

  Manifold.CountContacts:=0;

  Manifold.LocalRadius[0]:=0.0;
  Manifold.LocalRadius[1]:=0.0;

  Iteration:=0;
  while Iteration<2 do begin

   ContactManager.CountTemporaryContacts[ThreadIndex]:=0;

   if Iteration=0 then begin

    if Manifold.HaveData then begin

     if (Manifold.FaceQueryAB.Index>=0) and (Manifold.FaceQueryAB.Separation>0.0) then begin
      if TestEarlyFaceDirection(ShapeA,ShapeB,Manifold.FaceQueryAB) then begin
       // Still existent seperating axis from last frame found, so exit!
       exit;
      end else begin
       // Reject the try to rebuild the contact manifold from last frame, and process a new full seperating axis test
       Iteration:=1;
       continue;
      end;
     end else if (Manifold.FaceQueryBA.Index>=0) and (Manifold.FaceQueryBA.Separation>0.0) then begin
      if TestEarlyFaceDirection(ShapeB,ShapeA,Manifold.FaceQueryBA) then begin
       // Still existent seperating axis from last frame found, so exit!
       exit;
      end else begin
       // Reject the try to rebuild the contact manifold from last frame, and process a new full seperating axis test
       Iteration:=1;
       continue;
      end;
     end else if ((Manifold.EdgeQuery.IndexA>=0) and (Manifold.EdgeQuery.IndexB>=0)) and (Manifold.EdgeQuery.Separation>0.0) then begin
      if TestEarlyEdgeDirection(ShapeA,ShapeB,Manifold.EdgeQuery) then begin
       // Still existent seperating axis from last frame found, so exit!
       exit;
      end else begin
       // Reject the try to rebuild the contact manifold from last frame, and process a new full seperating axis test
       Iteration:=1;
       continue;
      end;
     end else if ((Manifold.FaceQueryAB.Index<0) or (Manifold.FaceQueryAB.Separation>0.0)) or
                 ((Manifold.FaceQueryBA.Index<0) or (Manifold.FaceQueryBA.Separation>0.0)) or
                 (((Manifold.EdgeQuery.IndexA<0) or (Manifold.EdgeQuery.IndexB<0)) or (Manifold.EdgeQuery.Separation>0.0)) then begin
      // Reject the try to rebuild the contact manifold from last frame, and process a new full seperating axis test
      Iteration:=1;
      continue;
     end else begin
      if TestEarlyFaceDirection(ShapeA,ShapeB,Manifold.FaceQueryAB) then begin
       // Still existent seperating axis from last frame found, so exit!
       exit;
      end else if TestEarlyFaceDirection(ShapeB,ShapeA,Manifold.FaceQueryBA) then begin
       // Still existent seperating axis from last frame found, so exit!
       exit;
      end else if TestEarlyEdgeDirection(ShapeA,ShapeB,Manifold.EdgeQuery) then begin
       // Still existent seperating axis from last frame found, so exit!
       exit;
{     end else if ((Manifold.EdgeQuery.IndexA>=0) and (Manifold.EdgeQuery.IndexB>=0)) and
                  ((Manifold.EdgeQuery.Separation>(Manifold.FaceQueryAB.Separation+eTolerance)) and (Manifold.EdgeQuery.Separation>(Manifold.FaceQueryBA.Separation+eTolerance))) then begin
       // Reject the try to rebuild the contact manifold from last frame, and process a new full seperating axis test
       Iteration:=1;
       continue;
      end else begin
       // Okay in this case, we can try to rebuild the contact manifold from last frame{}
      end else begin
       // Reject the try to rebuild the contact manifold from last frame, and process a new full seperating axis test
       Iteration:=1;
       continue;
      end;
     end;

    end else begin

     // We must process a full seperating axis test, since there are no last frame contact manifold data yet
     Iteration:=1;
     continue;

    end;

   end else begin

    Manifold.FaceQueryAB.Index:=-1;
    Manifold.FaceQueryAB.Separation:=3.4e+38;

    Manifold.FaceQueryBA.Index:=-1;
    Manifold.FaceQueryBA.Separation:=3.4e+38;

    Manifold.EdgeQuery.IndexA:=-1;
    Manifold.EdgeQuery.IndexB:=-1;
    Manifold.EdgeQuery.Separation:=3.4e+38;

    Manifold.HaveData:=true;

    QueryFaceDirections(ShapeA,ShapeB,Manifold.FaceQueryAB);
    if Manifold.FaceQueryAB.Separation>0.0 then begin
     exit;
    end;

    QueryFaceDirections(ShapeB,ShapeA,Manifold.FaceQueryBA);
    if Manifold.FaceQueryBA.Separation>0.0 then begin
     exit;
    end;

    QueryEdgeDirections(ShapeA,ShapeB,Manifold.EdgeQuery);
    if Manifold.EdgeQuery.Separation>0.0 then begin
     exit;
    end;

   end;

   ContactManager.CountTemporaryContacts[ThreadIndex]:=0;
   
   if ((Manifold.EdgeQuery.IndexA>=0) and (Manifold.EdgeQuery.IndexB>=0)) and
      ((Manifold.EdgeQuery.Separation>(Manifold.FaceQueryAB.Separation+eTolerance)) and (Manifold.EdgeQuery.Separation>(Manifold.FaceQueryBA.Separation+eTolerance))) then begin

    // Edge contact

    Manifold.HaveData:=false;

    EdgeA:=@ShapeA.ConvexHull.Edges[Manifold.EdgeQuery.IndexA];
    EdgeB:=@ShapeB.ConvexHull.Edges[Manifold.EdgeQuery.IndexB];

    a0:=Vector3TermMatrixMul(ShapeA.ConvexHull.Vertices[EdgeA^.Vertices[0]].Position,ShapeA.WorldTransform);
    a1:=Vector3TermMatrixMul(ShapeA.ConvexHull.Vertices[EdgeA^.Vertices[1]].Position,ShapeA.WorldTransform);
    b0:=Vector3TermMatrixMul(ShapeB.ConvexHull.Vertices[EdgeB^.Vertices[0]].Position,ShapeB.WorldTransform);
    b1:=Vector3TermMatrixMul(ShapeB.ConvexHull.Vertices[EdgeB^.Vertices[1]].Position,ShapeB.WorldTransform);

    if GetEdgeContact(pa,pb,a0,a1,b0,b1) then begin
{    Normal:=Vector3NormEx(Vector3Cross(Vector3Sub(a1,a0),Vector3Sub(b1,b0)));
     if Vector3Dot(Normal,Vector3Sub(ShapeB.GetCenter(ShapeB.WorldTransform),ShapeA.GetCenter(ShapeA.WorldTransform)))<0.0 then begin
      Normal:=Vector3Neg(Normal);
     end;
  //{}Normal:=Vector3TermMatrixMulBasis(Manifold.EdgeQuery.Normal,Shapes[1].WorldTransform);
     PenetrationDepth:=Vector3Dot(Vector3Sub(pb,pa),Normal);
     if PenetrationDepth<0.0 then begin    
      Manifold.ContactManifoldType:=kcmtEdges;
      Manifold.LocalNormal:=Vector3TermMatrixMulTransposedBasis(Normal,Shapes[0].WorldTransform);
      Contact:=@ContactManager.TemporaryContacts[ThreadIndex,ContactManager.CountTemporaryContacts[ThreadIndex]];
      inc(ContactManager.CountTemporaryContacts[ThreadIndex]);
      Contact^.LocalPoints[0]:=Vector3TermMatrixMulInverted(pa,Shapes[0].WorldTransform);
      Contact^.LocalPoints[1]:=Vector3TermMatrixMulInverted(pb,Shapes[1].WorldTransform);
      Contact^.Penetration:=PenetrationDepth;
      Contact^.FeaturePair.EdgeA:=Manifold.EdgeQuery.IndexA;
      Contact^.FeaturePair.FaceA:=$ff;
      Contact^.FeaturePair.EdgeB:=Manifold.EdgeQuery.IndexB;
      Contact^.FeaturePair.FaceB:=$ff;
     end;
    end;

   end else begin

    // Face contact

    if (Manifold.FaceQueryAB.Separation+EPSILON)>Manifold.FaceQueryBA.Separation then begin

     ReferenceFaceIndex:=Manifold.FaceQueryAB.Index;
     IncidentFaceIndex:=FindIncidentFaceIndex(ShapeA,Manifold.FaceQueryAB.Index,ShapeB);

     Manifold.ContactManifoldType:=kcmtFaceA;
     Manifold.LocalNormal:=ShapeA.ConvexHull.Faces[Manifold.FaceQueryAB.Index].Plane.Normal;

     ClipFaceContactPoints(ShapeA,ReferenceFaceIndex,ShapeB,IncidentFaceIndex,false);

    end else begin

     ReferenceFaceIndex:=FindIncidentFaceIndex(ShapeB,Manifold.FaceQueryBA.Index,ShapeA);
     IncidentFaceIndex:=Manifold.FaceQueryBA.Index;

     Manifold.ContactManifoldType:=kcmtFaceB;
     Manifold.LocalNormal:=ShapeB.ConvexHull.Faces[Manifold.FaceQueryBA.Index].Plane.Normal;

     ClipFaceContactPoints(ShapeB,IncidentFaceIndex,ShapeA,ReferenceFaceIndex,true);

    end;

   end;

   if ContactManager.CountTemporaryContacts[ThreadIndex]>0 then begin
    // Contacts found, reduce these down to four contacts with the largest area
    Manifold.CountContacts:=ContactManager.ReduceContacts(pointer(@ContactManager.TemporaryContacts[ThreadIndex,0]),ContactManager.CountTemporaryContacts[ThreadIndex],pointer(@Manifold.Contacts[0]));
    exit;
   end else begin
    if Iteration=0 then begin
     // We must process a new full seperating axis test, since the last frame contact manifold could not rebuilt.
     inc(Iteration);
    end else begin
     // No contacts found
     exit;
    end;
   end;

  end;

 end;
var Index,SubIndex:longint;
    ShapeA,ShapeB:TKraftShape;
    MeshShape:TKraftShapeMesh;
    HasContact:boolean;
    MeshTriangle:PKraftMeshTriangle;
    Contact,BestOldContact,OldContact:PKraftContact;
    BestContactDistance,ContactDistance:TKraftScalar;
    OldManifoldContacts:array[0..MAX_CONTACTS-1] of TKraftContact;
begin

 Flags:=Flags+[kcfEnabled];

 OldManifoldCountContacts:=Manifold.CountContacts;
 for Index:=0 to OldManifoldCountContacts-1 do begin
  OldManifoldContacts[Index]:=Manifold.Contacts[Index];
 end;

 Manifold.ContactManifoldType:=kcmtUnknown;

 Manifold.CountContacts:=0;

 ShapeA:=Shapes[0];
 ShapeB:=Shapes[1];

 if assigned(MeshContactPair) then begin
  if (ElementIndex>=0) and assigned(TriangleShape) and (ShapeB is TKraftShapeMesh) then begin
   MeshShape:=TKraftShapeMesh(ShapeB);
   ShapeB:=TriangleShape;
   ShapeTriangle:=TKraftShapeTriangle(TriangleShape);
   MeshTriangle:=@MeshShape.Mesh.Triangles[ElementIndex];
   ShapeTriangle.WorldTransform:=MeshShape.WorldTransform;
   ShapeTriangle.ConvexHull.Vertices[0].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[0]];
   ShapeTriangle.ConvexHull.Vertices[1].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[1]];
   ShapeTriangle.ConvexHull.Vertices[2].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[2]];
   ShapeTriangle.UpdateData;
  end else begin
   exit;
  end;
 end;

 HasContact:=false;

 if (Shapes[0]<>Shapes[1]) and (Shapes[0].RigidBody<>Shapes[1].RigidBody) then begin

  case ShapeA.ShapeType of
   kstSphere:begin
    case ShapeB.ShapeType of
     kstSphere:begin
      CollideSphereWithSphere(TKraftShapeSphere(ShapeA),TKraftShapeSphere(ShapeB));
     end;
     kstCapsule:begin
      CollideSphereWithCapsule(TKraftShapeSphere(ShapeA),TKraftShapeCapsule(ShapeB));
     end;
     kstConvexHull:begin
      CollideSphereWithConvexHull(TKraftShapeSphere(ShapeA),TKraftShapeConvexHull(ShapeB));
     end;
     kstBox:begin
      CollideSphereWithBox(TKraftShapeSphere(ShapeA),TKraftShapeBox(ShapeB));
     end;
     kstPlane:begin
      CollideSphereWithPlane(TKraftShapeSphere(ShapeA),TKraftShapePlane(ShapeB));
     end;
     kstTriangle:begin
      CollideSphereWithTriangle(TKraftShapeSphere(ShapeA),TKraftShapeTriangle(ShapeB));
     end;
    end;
   end;
   kstCapsule:begin
    case ShapeB.ShapeType of
     kstCapsule:begin
      CollideCapsuleWithCapsule(TKraftShapeCapsule(ShapeA),TKraftShapeCapsule(ShapeB));
     end;
     kstConvexHull,kstBox,kstPlane,kstTriangle:begin
      CollideCapsuleWithConvexHull(TKraftShapeCapsule(ShapeA),TKraftShapeConvexHull(ShapeB));
     end;
{    kstConvexHull,kstBox,kstPlane:begin
      CollideCapsuleWithConvexHull(TKraftShapeCapsule(ShapeA),TKraftShapeConvexHull(ShapeB));
     end;
     kstTriangle:begin
      CollideCapsuleWithTriangle(TKraftShapeCapsule(ShapeA),TKraftShapeTriangle(ShapeB));
     end;{}
    end;
   end;
   kstConvexHull,kstBox,kstPlane,kstTriangle:begin
    case ShapeB.ShapeType of
     kstConvexHull,kstBox,kstPlane,kstTriangle:begin
      CollideConvexHullWithConvexHull(TKraftShapeConvexHull(ShapeA),TKraftShapeConvexHull(ShapeB));
     end;
    end;
   end;
  end;

  if ((ksfSensor in Shapes[0].Flags) or (ksfSensor in Shapes[1].Flags)) or
     ((krbfSensor in RigidBodies[0].Flags) or (krbfSensor in RigidBodies[1].Flags)) then begin

   HasContact:=Manifold.CountContacts>0;

   Manifold.ContactManifoldType:=kcmtUnknown;
   Manifold.CountContacts:=0;
    
  end else begin

   HasContact:=Manifold.CountContacts>0;

   for Index:=0 to Manifold.CountContacts-1 do begin
    Contact:=@Manifold.Contacts[Index];
    BestOldContact:=nil;
    if Contact^.FeaturePair.Key=$ffffffff then begin
     BestContactDistance:=ContactManager.Physics.ContactBreakingThreshold;
     for SubIndex:=0 to OldManifoldCountContacts-1 do begin
      OldContact:=@OldManifoldContacts[SubIndex];
      ContactDistance:=Vector3Dist(Contact^.LocalPoints[0],OldContact^.LocalPoints[0]);
      if BestContactDistance>ContactDistance then begin
       BestContactDistance:=ContactDistance;
       BestOldContact:=OldContact;
      end;
     end;
    end else begin
     for SubIndex:=0 to OldManifoldCountContacts-1 do begin
      OldContact:=@OldManifoldContacts[SubIndex];
      if Contact^.FeaturePair.Key=OldContact^.FeaturePair.Key then begin
       BestOldContact:=OldContact;
       break;
      end;
     end;
    end;
    if assigned(BestOldContact) then begin
     Contact^.NormalImpulse:=BestOldContact^.NormalImpulse;
     Contact^.TangentImpulse[0]:=BestOldContact^.TangentImpulse[0];
     Contact^.TangentImpulse[1]:=BestOldContact^.TangentImpulse[1];
     Contact^.WarmStartState:=Max(BestOldContact^.WarmStartState,BestOldContact^.WarmStartState+1);
    end else begin
     Contact^.NormalImpulse:=0.0;
     Contact^.TangentImpulse[0]:=0.0;
     Contact^.TangentImpulse[1]:=0.0;
     Contact^.WarmStartState:=0;
    end;
   end;
  end;

 end;

 if HasContact then begin
  if kcfColliding in Flags then begin
   Include(Flags,kcfWasColliding);
  end else begin
   Include(Flags,kcfColliding);
  end;
 end else begin
  if kcfColliding in Flags then begin
   Flags:=(Flags-[kcfColliding])+[kcfWasColliding];
  end else begin
   Exclude(Flags,kcfWasColliding);
  end;
 end;

{if ShapeB.ShapeType=kstPlane then begin
  writeln(ContactManager.Physics.HighResolutionTimer.GetTime:16,' ',Manifold.CountContacts:4);
 end;{}

end;

constructor TKraftMeshContactPair.Create(const AContactManager:TKraftContactManager);
begin
 inherited Create;

 ContactManager:=AContactManager;

 if assigned(ContactManager.MeshContactPairLast) then begin
  ContactManager.MeshContactPairLast.Next:=self;
  Previous:=ContactManager.MeshContactPairLast;
 end else begin
  ContactManager.MeshContactPairFirst:=self;
  Previous:=nil;
 end;
 ContactManager.MeshContactPairLast:=self;
 Next:=nil;

 HashBucket:=-1;
 HashPrevious:=nil;
 HashNext:=nil;

 IsOnFreeList:=false;

 Flags:=[];

 inc(ContactManager.CountMeshContactPairs);

 ShapeConvex:=nil;
 ShapeMesh:=nil;

 RigidBodyConvex:=nil;
 RigidBodyMesh:=nil;

end;

destructor TKraftMeshContactPair.Destroy;
begin

 RemoveFromHashTable;

 if IsOnFreeList then begin
  if assigned(Previous) then begin
   Previous.Next:=Next;
  end else if ContactManager.MeshContactPairFirstFree=self then begin
   ContactManager.MeshContactPairFirstFree:=Next;
  end;
  if assigned(Next) then begin
   Next.Previous:=Previous;
  end else if ContactManager.MeshContactPairLastFree=self then begin
   ContactManager.MeshContactPairLastFree:=Previous;
  end;
  Previous:=nil;
  Next:=nil;
 end else begin
  if assigned(Previous) then begin
   Previous.Next:=Next;
  end else if ContactManager.MeshContactPairFirst=self then begin
   ContactManager.MeshContactPairFirst:=Next;
  end;
  if assigned(Next) then begin
   Next.Previous:=Previous;
  end else if ContactManager.MeshContactPairLast=self then begin
   ContactManager.MeshContactPairLast:=Previous;
  end;
  Previous:=nil;
  Next:=nil;
 end;

 dec(ContactManager.CountMeshContactPairs);

 inherited Destroy;
end;

procedure TKraftMeshContactPair.MoveToFreeList;
begin
 if not IsOnFreeList then begin

  IsOnFreeList:=true;

  if assigned(Previous) then begin
   Previous.Next:=Next;
  end else if ContactManager.MeshContactPairFirst=self then begin
   ContactManager.MeshContactPairFirst:=Next;
  end;
  if assigned(Next) then begin
   Next.Previous:=Previous;
  end else if ContactManager.MeshContactPairLast=self then begin
   ContactManager.MeshContactPairLast:=Previous;
  end;

  if assigned(ContactManager.MeshContactPairLastFree) then begin
   ContactManager.MeshContactPairLastFree.Next:=self;
   Previous:=ContactManager.MeshContactPairLastFree;
  end else begin
   ContactManager.MeshContactPairFirstFree:=self;
   Previous:=nil;
  end;
  ContactManager.MeshContactPairLastFree:=self;
  Next:=nil;

 end;
end;

procedure TKraftMeshContactPair.MoveFromFreeList;
begin
 if IsOnFreeList then begin

  IsOnFreeList:=false;

  Flags:=[];

  if assigned(Previous) then begin
   Previous.Next:=Next;
  end else if ContactManager.MeshContactPairFirstFree=self then begin
   ContactManager.MeshContactPairFirstFree:=Next;
  end;
  if assigned(Next) then begin
   Next.Previous:=Previous;
  end else if ContactManager.MeshContactPairLastFree=self then begin
   ContactManager.MeshContactPairLastFree:=Previous;
  end;

  if assigned(ContactManager.MeshContactPairLast) then begin
   ContactManager.MeshContactPairLast.Next:=self;
   Previous:=ContactManager.MeshContactPairLast;
  end else begin
   ContactManager.MeshContactPairFirst:=self;
   Previous:=nil;
  end;
  ContactManager.MeshContactPairLast:=self;
  Next:=nil;

 end;
end;

procedure TKraftMeshContactPair.AddToHashTable; {$ifdef caninline}inline;{$endif}
var HashTableBucket:PKraftMeshContactPairHashTableBucket;
begin
 if HashBucket<0 then begin
  HashBucket:=HashTwoPointers(ShapeConvex,ShapeMesh) and high(TKraftMeshContactPairHashTable);
  HashTableBucket:=@ContactManager.MeshContactPairHashTable[HashBucket];
  if assigned(HashTableBucket^.First) then begin
   HashTableBucket^.First.HashPrevious:=self;
   HashNext:=HashTableBucket^.First;
  end else begin
   HashTableBucket^.Last:=self;
   HashNext:=nil;
  end;
  HashTableBucket^.First:=self;
  HashPrevious:=nil;
 end;
end;

procedure TKraftMeshContactPair.RemoveFromHashTable; {$ifdef caninline}inline;{$endif}
var HashTableBucket:PKraftMeshContactPairHashTableBucket;
begin
 if HashBucket>=0 then begin
  HashTableBucket:=@ContactManager.MeshContactPairHashTable[HashBucket];
  HashBucket:=-1;
  if assigned(HashPrevious) then begin
   HashPrevious.HashNext:=HashNext;
  end else if HashTableBucket^.First=self then begin
   HashTableBucket^.First:=HashNext;
  end;
  if assigned(HashNext) then begin
   HashNext.HashPrevious:=HashPrevious;
  end else if HashTableBucket^.Last=self then begin
   HashTableBucket^.Last:=HashPrevious;
  end;
  HashPrevious:=nil;
  HashNext:=nil;
 end;
end;

procedure TKraftMeshContactPair.Query;
var SkipListNodeIndex,TriangleIndex{,Index{}:longint;
    SkipListNode:PKraftMeshSkipListNode;
    Triangle:PKraftMeshTriangle;
//  MeshTriangleContactQueueItem:PKraftContactManagerMeshTriangleContactQueueItem;
begin
 SkipListNodeIndex:=0;
 while SkipListNodeIndex<TKraftShapeMesh(ShapeMesh).Mesh.CountSkipListNodes do begin
  SkipListNode:=@TKraftShapeMesh(ShapeMesh).Mesh.SkipListNodes[SkipListNodeIndex];
  if AABBIntersect(SkipListNode^.AABB,ConvexAABBInMeshLocalSpace) then begin
   TriangleIndex:=SkipListNode^.TriangleIndex;
   while TriangleIndex>=0 do begin
    Triangle:=@TKraftShapeMesh(ShapeMesh).Mesh.Triangles[TriangleIndex];
{   if AABBIntersect(Triangle^.AABB,ConvexAABBInMeshLocalSpace) then begin
     Index:=ContactManager.CountMeshTriangleContactQueueItems;
     inc(ContactManager.CountMeshTriangleContactQueueItems);
     if ContactManager.CountMeshTriangleContactQueueItems>length(ContactManager.MeshTriangleContactQueueItems) then begin
      SetLength(ContactManager.MeshTriangleContactQueueItems,ContactManager.CountMeshTriangleContactQueueItems*2);
     end;
     MeshTriangleContactQueueItem:=@ContactManager.MeshTriangleContactQueueItems[Index];
     MeshTriangleContactQueueItem^.MeshContactPair:=self;
     MeshTriangleContactQueueItem^.TriangleIndex:=TriangleIndex;
    end;
(*} if AABBIntersect(Triangle^.AABB,ConvexAABBInMeshLocalSpace) and not ContactManager.HasDuplicateContact(RigidBodyConvex,RigidBodyMesh,ShapeConvex,ShapeMesh,TriangleIndex) then begin
     ContactManager.AddConvexContact(RigidBodyConvex,RigidBodyMesh,ShapeConvex,ShapeMesh,TriangleIndex,self);
    end;(**)
    TriangleIndex:=Triangle^.Next;
   end;
   inc(SkipListNodeIndex);
  end else begin
   SkipListNodeIndex:=SkipListNode^.SkipToNodeIndex;
  end;
 end;
end;

procedure TKraftMeshContactPair.Update;
var NewConvexAABBInMeshLocalSpace:TKraftAABB;
    Transform:TKraftMatrix4x4;
    Displacement,BoundsExpansion:TKraftVector3;
    AABBMaxExpansion:TKraftScalar;
begin
 Transform:=Matrix4x4TermMulSimpleInverted(ShapeConvex.WorldTransform,ShapeMesh.WorldTransform);
 NewConvexAABBInMeshLocalSpace:=AABBTransform(ShapeConvex.ShapeAABB,Transform);
 if not AABBContains(ConvexAABBInMeshLocalSpace,NewConvexAABBInMeshLocalSpace) then begin
  Displacement:=Vector3TermMatrixMulBasis(Vector3ScalarMul(RigidBodyConvex.LinearVelocity,RigidBodyConvex.Physics.WorldDeltaTime),Transform);
  BoundsExpansion:=Vector3ScalarMul(Vector3(ShapeConvex.AngularMotionDisc,ShapeConvex.AngularMotionDisc,ShapeConvex.AngularMotionDisc),Vector3Length(RigidBodyConvex.AngularVelocity)*RigidBodyConvex.Physics.WorldDeltaTime*AABB_MULTIPLIER);
  AABBMaxExpansion:=Max(AABB_MAX_EXPANSION,ShapeConvex.ShapeSphere.Radius*AABB_MAX_EXPANSION);
  if Vector3LengthSquared(Displacement)>sqr(AABBMaxExpansion) then begin
   Vector3Scale(Displacement,AABBMaxExpansion/Vector3Length(Displacement));
  end;
  if Vector3LengthSquared(BoundsExpansion)>sqr(AABBMaxExpansion) then begin
   Vector3Scale(BoundsExpansion,AABBMaxExpansion/Vector3Length(BoundsExpansion));
  end;
  ConvexAABBInMeshLocalSpace:=AABBStretch(NewConvexAABBInMeshLocalSpace,Displacement,BoundsExpansion);
  Query;
 end;
end;

constructor TKraftContactManager.Create(const APhysics:TKraft);
var ThreadIndex:longint;
begin
 inherited Create;

 Physics:=APhysics;

 ContactPairFirst:=nil;
 ContactPairLast:=nil;

 FreeContactPairs:=nil;

 CountContactPairs:=0;

 MeshContactPairFirst:=nil;
 MeshContactPairLast:=nil;

 MeshContactPairFirstFree:=nil;
 MeshContactPairLastFree:=nil;

 CountMeshContactPairs:=0;

 OnContactBegin:=nil;
 OnContactEnd:=nil;
 OnContactStay:=nil;

 OnCanCollide:=nil;

 for ThreadIndex:=0 to MAX_THREADS-1 do begin
  ConvexHullVertexLists[ThreadIndex,0]:=TKraftConvexHullVertexList.Create;
  ConvexHullVertexLists[ThreadIndex,1]:=TKraftConvexHullVertexList.Create;
 end;

{$ifdef DebugDraw}
 CountDebugConvexHullVertexLists:=0;
 for ThreadIndex:=0 to high(DebugConvexHullVertexLists) do begin
  DebugConvexHullVertexLists[ThreadIndex]:=TKraftConvexHullVertexList.Create;
 end;
{$endif}

 ActiveContactPairs:=nil;
 SetLength(ActiveContactPairs,256);
 CountActiveContactPairs:=0;

 MeshTriangleContactQueueItems:=nil;
 SetLength(MeshTriangleContactQueueItems,65536);
 CountMeshTriangleContactQueueItems:=0;

 FillChar(ConvexConvexContactPairHashTable,SizeOf(TKraftContactPairHashTable),AnsiChar(#0));

 FillChar(ConvexMeshTriangleContactPairHashTable,SizeOf(TKraftContactPairHashTable),AnsiChar(#0));

 FillChar(MeshContactPairHashTable,SizeOf(TKraftMeshContactPairHashTable),AnsiChar(#0));
 
end;

destructor TKraftContactManager.Destroy;
var ThreadIndex:longint;
    NextContactPair:PKraftContactPair;
begin

 SetLength(ActiveContactPairs,0);

 SetLength(MeshTriangleContactQueueItems,0);

 while assigned(ContactPairFirst) do begin
  RemoveContact(ContactPairFirst);
 end;

 while assigned(FreeContactPairs) do begin
  NextContactPair:=FreeContactPairs^.Next;
  FreeMem(FreeContactPairs);
  FreeContactPairs:=NextContactPair;
 end;

 while assigned(MeshContactPairFirst) do begin
  MeshContactPairFirst.Free;
 end;

 while assigned(MeshContactPairFirstFree) do begin
  MeshContactPairFirstFree.Free;
 end;

//Assert(CountContactPairs=0);
//Assert(CountMeshContactPairs=0);

 for ThreadIndex:=0 to MAX_THREADS-1 do begin
  FreeAndNil(ConvexHullVertexLists[ThreadIndex,0]);
  FreeAndNil(ConvexHullVertexLists[ThreadIndex,1]);
 end;

{$ifdef DebugDraw}
 for ThreadIndex:=0 to high(DebugConvexHullVertexLists) do begin
  DebugConvexHullVertexLists[ThreadIndex].Free;
 end;
{$endif}

 inherited Destroy;
end;

function TKraftContactManager.HasDuplicateContact(const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AShapeA,AShapeB:TKraftShape;const AElementIndex:longint=-1):boolean;
var HashTableBucket:PKraftContactPairHashTableBucket;
    ContactPair:PKraftContactPair;
begin
 result:=false;
 if AElementIndex<0 then begin
  if ptruint(AShapeA)<ptruint(AShapeB) then begin
   HashTableBucket:=@ConvexConvexContactPairHashTable[HashTwoPointers(AShapeA,AShapeB) and high(TKraftContactPairHashTable)];
  end else begin
   HashTableBucket:=@ConvexConvexContactPairHashTable[HashTwoPointers(AShapeB,AShapeA) and high(TKraftContactPairHashTable)];
  end;
  ContactPair:=HashTableBucket^.First;
  while assigned(ContactPair) do begin
   if ((ContactPair^.Shapes[0]=AShapeA) and (ContactPair^.Shapes[1]=AShapeB)) or
      ((ContactPair^.Shapes[0]=AShapeB) and (ContactPair^.Shapes[1]=AShapeA)) then begin
    result:=true;
    exit;
   end;
   ContactPair:=ContactPair^.Next;
  end;
 end else begin
  if ptruint(AShapeA)<ptruint(AShapeB) then begin
   HashTableBucket:=@ConvexMeshTriangleContactPairHashTable[HashTwoPointersAndOneLongword(AShapeA,AShapeB,AElementIndex) and high(TKraftContactPairHashTable)];
  end else begin
   HashTableBucket:=@ConvexMeshTriangleContactPairHashTable[HashTwoPointersAndOneLongword(AShapeB,AShapeA,AElementIndex) and high(TKraftContactPairHashTable)];
  end;
  ContactPair:=HashTableBucket^.First;
  while assigned(ContactPair) do begin
   if (ContactPair^.ElementIndex=AElementIndex) and
      (((ContactPair^.Shapes[0]=AShapeA) and (ContactPair^.Shapes[1]=AShapeB)) or
       ((ContactPair^.Shapes[0]=AShapeB) and (ContactPair^.Shapes[1]=AShapeA))) then begin
    result:=true;
    exit;
   end;
   ContactPair:=ContactPair^.Next;
  end;
 end;
end;            

procedure TKraftContactManager.AddConvexContact(const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AShapeA,AShapeB:TKraftShape;const AElementIndex:longint=-1;const AMeshContactPair:TKraftMeshContactPair=nil);
var i:longint;
    ContactPair:PKraftContactPair;
    HashTableBucket:PKraftContactPairHashTableBucket;
begin

 if assigned(FreeContactPairs) then begin
  ContactPair:=FreeContactPairs;
  FreeContactPairs:=ContactPair^.Next;
 end else begin
  GetMem(ContactPair,SizeOf(TKraftContactPair));
 end;
 FillChar(ContactPair^,SizeOf(TKraftContactPair),AnsiChar(#0));

 ContactPair^.Manifold.HaveData:=false;

 ContactPair^.Island:=nil;

 ContactPair^.Shapes[0]:=AShapeA;
 ContactPair^.Shapes[1]:=AShapeB;

 ContactPair^.ElementIndex:=AElementIndex;

 if AElementIndex<0 then begin
  if ptruint(AShapeA)<ptruint(AShapeB) then begin
   ContactPair^.HashBucket:=HashTwoPointers(AShapeA,AShapeB) and high(TKraftContactPairHashTable);
  end else begin
   ContactPair^.HashBucket:=HashTwoPointers(AShapeB,AShapeA) and high(TKraftContactPairHashTable);
  end;
  HashTableBucket:=@ConvexConvexContactPairHashTable[ContactPair^.HashBucket];
 end else begin
  if ptruint(AShapeA)<ptruint(AShapeB) then begin
   ContactPair^.HashBucket:=HashTwoPointersAndOneLongword(AShapeA,AShapeB,AElementIndex) and high(TKraftContactPairHashTable);
  end else begin
   ContactPair^.HashBucket:=HashTwoPointersAndOneLongword(AShapeB,AShapeA,AElementIndex) and high(TKraftContactPairHashTable);
  end;
  HashTableBucket:=@ConvexMeshTriangleContactPairHashTable[ContactPair^.HashBucket];
 end;
 if assigned(HashTableBucket^.First) then begin
  HashTableBucket^.First.HashPrevious:=ContactPair;
  ContactPair^.HashNext:=HashTableBucket^.First;
 end else begin
  HashTableBucket^.Last:=ContactPair;
  ContactPair^.HashNext:=nil;
 end;
 HashTableBucket^.First:=ContactPair;
 ContactPair^.HashPrevious:=nil;

 ContactPair^.MeshContactPair:=AMeshContactPair;

 ContactPair^.RigidBodies[0]:=ARigidBodyA;
 ContactPair^.RigidBodies[1]:=ARigidBodyB;

 ContactPair^.Manifold.CountContacts:=0;

 for i:=low(ContactPair^.Manifold.Contacts) to high(ContactPair^.Manifold.Contacts) do begin
  ContactPair^.Manifold.Contacts[i].WarmStartState:=0;
 end;

 ContactPair^.Flags:=[kcfEnabled];

 ContactPair^.Friction:=sqrt(AShapeA.Friction*AShapeB.Friction);

 ContactPair^.Restitution:=max(AShapeA.Restitution,AShapeB.Restitution);

 if assigned(ContactPairLast) then begin
  ContactPair^.Previous:=ContactPairLast;
  ContactPairLast^.Next:=ContactPair;
 end else begin
  ContactPair^.Previous:=nil;
  ContactPairFirst:=ContactPair;
 end;
 ContactPair^.Next:=nil;
 ContactPairLast:=ContactPair;

 ContactPair^.Edges[0].OtherRigidBody:=ARigidBodyB;
 ContactPair^.Edges[0].ContactPair:=ContactPair;

 if assigned(ARigidBodyA.ContactPairEdgeLast) then begin
  ContactPair^.Edges[0].Previous:=ARigidBodyA.ContactPairEdgeLast;
  ARigidBodyA.ContactPairEdgeLast^.Next:=@ContactPair^.Edges[0];
 end else begin
  ContactPair^.Edges[0].Previous:=nil;
  ARigidBodyA.ContactPairEdgeFirst:=@ContactPair^.Edges[0];
 end;
 ContactPair^.Edges[0].Next:=nil;
 ARigidBodyA.ContactPairEdgeLast:=@ContactPair^.Edges[0];

 ContactPair^.Edges[1].OtherRigidBody:=ARigidBodyA;
 ContactPair^.Edges[1].ContactPair:=ContactPair;

 if assigned(ARigidBodyB.ContactPairEdgeLast) then begin
  ContactPair^.Edges[1].Previous:=ARigidBodyB.ContactPairEdgeLast;
  ARigidBodyB.ContactPairEdgeLast^.Next:=@ContactPair^.Edges[1];
 end else begin
  ContactPair^.Edges[1].Previous:=nil;
  ARigidBodyB.ContactPairEdgeFirst:=@ContactPair^.Edges[1];
 end;
 ContactPair^.Edges[1].Next:=nil;
 ARigidBodyB.ContactPairEdgeLast:=@ContactPair^.Edges[1];

 ARigidBodyB.SetToAwake;
 ARigidBodyA.SetToAwake;

 inc(CountContactPairs);

end;

procedure TKraftContactManager.AddMeshContact(const ARigidBodyConvex,ARigidBodyMesh:TKraftRigidBody;const AShapeConvex,AShapeMesh:TKraftShape);
var HashTableBucket:PKraftMeshContactPairHashTableBucket;
    MeshContactPair:TKraftMeshContactPair;
    Transform:TKraftMatrix4x4;
    Displacement,BoundsExpansion:TKraftVector3;
    AABBMaxExpansion:TKraftScalar;
begin

 HashTableBucket:=@MeshContactPairHashTable[HashTwoPointers(AShapeConvex,AShapeMesh) and high(TKraftMeshContactPairHashTable)];
 MeshContactPair:=HashTableBucket.First;
 while assigned(MeshContactPair) do begin
  if (MeshContactPair.ShapeConvex=AShapeConvex) and (MeshContactPair.ShapeMesh=AShapeMesh) then begin
   exit;
  end;
  MeshContactPair:=MeshContactPair.HashNext;
 end;

 if assigned(MeshContactPairFirstFree) then begin
  MeshContactPair:=MeshContactPairFirstFree;
  MeshContactPair.MoveFromFreeList;
 end else begin
  MeshContactPair:=TKraftMeshContactPair.Create(self);
 end;

 MeshContactPair.RigidBodyConvex:=ARigidBodyConvex;
 MeshContactPair.RigidBodyMesh:=ARigidBodyMesh;

 MeshContactPair.ShapeConvex:=AShapeConvex;
 MeshContactPair.ShapeMesh:=AShapeMesh;

 MeshContactPair.AddToHashTable;

 Transform:=Matrix4x4TermMulSimpleInverted(MeshContactPair.ShapeConvex.WorldTransform,MeshContactPair.ShapeMesh.WorldTransform);
 Displacement:=Vector3TermMatrixMulBasis(Vector3ScalarMul(MeshContactPair.RigidBodyConvex.LinearVelocity,MeshContactPair.RigidBodyConvex.Physics.WorldDeltaTime),Transform);
 BoundsExpansion:=Vector3ScalarMul(Vector3(MeshContactPair.ShapeConvex.AngularMotionDisc,MeshContactPair.ShapeConvex.AngularMotionDisc,MeshContactPair.ShapeConvex.AngularMotionDisc),Vector3Length(MeshContactPair.RigidBodyConvex.AngularVelocity)*MeshContactPair.RigidBodyConvex.Physics.WorldDeltaTime*AABB_MULTIPLIER);
 AABBMaxExpansion:=Max(AABB_MAX_EXPANSION,MeshContactPair.ShapeConvex.ShapeSphere.Radius*AABB_MAX_EXPANSION);
 if Vector3LengthSquared(Displacement)>sqr(AABBMaxExpansion) then begin
  Vector3Scale(Displacement,AABBMaxExpansion/Vector3Length(Displacement));
 end;
 if Vector3LengthSquared(BoundsExpansion)>sqr(AABBMaxExpansion) then begin
  Vector3Scale(BoundsExpansion,AABBMaxExpansion/Vector3Length(BoundsExpansion));
 end;
 MeshContactPair.ConvexAABBInMeshLocalSpace:=AABBStretch(AABBTransform(MeshContactPair.ShapeConvex.ShapeAABB,Transform),Displacement,BoundsExpansion);

 MeshContactPair.Query;

end;

procedure TKraftContactManager.AddContact(const AShapeA,AShapeB:TKraftShape);
var RigidBodyA,RigidBodyB:TKraftRigidBody;
begin

 RigidBodyA:=AShapeA.RigidBody;
 RigidBodyB:=AShapeB.RigidBody;
                                                                        
 if (not RigidBodyA.CanCollideWith(RigidBodyB)) or (assigned(OnCanCollide) and not OnCanCollide(AShapeA,AShapeB)) then begin
  exit;
 end;

 if AShapeA.IsMesh then begin

  AddMeshContact(RigidBodyB,RigidBodyA,AShapeB,AShapeA);

 end else if AShapeB.IsMesh then begin

  AddMeshContact(RigidBodyA,RigidBodyB,AShapeA,AShapeB);

 end else begin

  if not HasDuplicateContact(RigidBodyA,RigidBodyB,AShapeA,AShapeB,-1) then begin
   AddConvexContact(RigidBodyA,RigidBodyB,AShapeA,AShapeB,-1);
  end;

 end;

end;

procedure TKraftContactManager.RemoveContact(AContactPair:PKraftContactPair);
var RigidBodyA,RigidBodyB:TKraftRigidBody;
    HashTableBucket:PKraftContactPairHashTableBucket;
begin

 if AContactPair^.ElementIndex<0 then begin
  HashTableBucket:=@ConvexConvexContactPairHashTable[AContactPair^.HashBucket];
 end else begin
  HashTableBucket:=@ConvexMeshTriangleContactPairHashTable[AContactPair^.HashBucket];
 end;
 AContactPair^.HashBucket:=-1;
 if assigned(AContactPair^.HashPrevious) then begin
  AContactPair^.HashPrevious^.HashNext:=AContactPair^.HashNext;
 end else if HashTableBucket^.First=AContactPair then begin
  HashTableBucket^.First:=AContactPair^.HashNext;
 end;
 if assigned(AContactPair^.HashNext) then begin
  AContactPair^.HashNext^.HashPrevious:=AContactPair^.HashPrevious;
 end else if HashTableBucket^.Last=AContactPair then begin
  HashTableBucket^.Last:=AContactPair^.HashPrevious;
 end;
 AContactPair^.HashPrevious:=nil;
 AContactPair^.HashNext:=nil;

 RigidBodyA:=AContactPair.Shapes[0].RigidBody;
 RigidBodyB:=AContactPair.Shapes[1].RigidBody;

 if assigned(AContactPair^.Edges[0].Previous) then begin
  AContactPair^.Edges[0].Previous^.Next:=AContactPair^.Edges[0].Next;
 end else if RigidBodyA.ContactPairEdgeFirst=@AContactPair^.Edges[0] then begin
  RigidBodyA.ContactPairEdgeFirst:=AContactPair^.Edges[0].Next;
 end;
 if assigned(AContactPair^.Edges[0].Next) then begin
  AContactPair^.Edges[0].Next^.Previous:=AContactPair^.Edges[0].Previous;
 end else if RigidBodyA.ContactPairEdgeLast=@AContactPair^.Edges[0] then begin
  RigidBodyA.ContactPairEdgeLast:=AContactPair^.Edges[0].Previous;
 end;
 AContactPair^.Edges[0].Previous:=nil;
 AContactPair^.Edges[0].Next:=nil;

 if assigned(AContactPair^.Edges[1].Previous) then begin
  AContactPair^.Edges[1].Previous^.Next:=AContactPair^.Edges[1].Next;
 end else if RigidBodyB.ContactPairEdgeFirst=@AContactPair^.Edges[1] then begin
  RigidBodyB.ContactPairEdgeFirst:=AContactPair^.Edges[1].Next;
 end;
 if assigned(AContactPair^.Edges[1].Next) then begin
  AContactPair^.Edges[1].Next^.Previous:=AContactPair^.Edges[1].Previous;
 end else if RigidBodyB.ContactPairEdgeLast=@AContactPair^.Edges[1] then begin
  RigidBodyB.ContactPairEdgeLast:=AContactPair^.Edges[1].Previous;
 end;
 AContactPair^.Edges[1].Previous:=nil;
 AContactPair^.Edges[1].Next:=nil;

 RigidBodyA.SetToAwake;
 RigidBodyB.SetToAwake;

 if assigned(AContactPair^.Previous) then begin
  AContactPair^.Previous^.Next:=AContactPair^.Next;
 end else if ContactPairFirst=AContactPair then begin
  ContactPairFirst:=AContactPair^.Next;
 end;
 if assigned(AContactPair^.Next) then begin
  AContactPair^.Next^.Previous:=AContactPair^.Previous;
 end else if ContactPairLast=AContactPair then begin
  ContactPairLast:=AContactPair^.Previous;
 end;
 AContactPair^.Previous:=nil;
 AContactPair^.Next:=FreeContactPairs;
 FreeContactPairs:=AContactPair;

 dec(CountContactPairs);

end;

procedure TKraftContactManager.RemoveMeshContact(AMeshContactPair:TKraftMeshContactPair);
begin
 AMeshContactPair.RemoveFromHashTable;
 AMeshContactPair.MoveToFreeList;
end;

procedure TKraftContactManager.RemoveContactsFromRigidBody(ARigidBody:TKraftRigidBody);
var ContactPairEdge,NextContactPairEdge:PKraftContactPairEdge;
    MeshContactPair,NextMeshContactPair:TKraftMeshContactPair;
begin
 ContactPairEdge:=ARigidBody.ContactPairEdgeFirst;
 while assigned(ContactPairEdge) do begin
  NextContactPairEdge:=ContactPairEdge^.Next;
  RemoveContact(ContactPairEdge^.ContactPair);
  ContactPairEdge:=NextContactPairEdge;
 end;
 ARigidBody.ContactPairEdgeFirst:=nil;
 ARigidBody.ContactPairEdgeLast:=nil;
 MeshContactPair:=MeshContactPairFirst;
 while assigned(MeshContactPair) do begin
  NextMeshContactPair:=MeshContactPair.Next;
  if (MeshContactPair.RigidBodyConvex=ARigidBody) or (MeshContactPair.RigidBodyMesh=ARigidBody) then begin
   RemoveMeshContact(MeshContactPair);
  end;
  MeshContactPair:=NextMeshContactPair;
 end;
end;

procedure TKraftContactManager.DoBroadPhase;
var StartTime:int64;
begin
 StartTime:=Physics.HighResolutionTimer.GetTime;
 Physics.BroadPhase.UpdatePairs;
 inc(Physics.BroadPhaseTime,Physics.HighResolutionTimer.GetTime-StartTime);
end;

procedure TKraftContactManager.DoMidPhase;
var Index:longint;
    MeshContactPair:TKraftMeshContactPair;
    MeshTriangleContactQueueItem:PKraftContactManagerMeshTriangleContactQueueItem;
    StartTime:int64;
begin
 StartTime:=Physics.HighResolutionTimer.GetTime;

 MeshContactPair:=MeshContactPairFirst;
 while assigned(MeshContactPair) do begin
  MeshContactPair.Update;
  MeshContactPair:=MeshContactPair.Next;
 end;

 if CountMeshTriangleContactQueueItems>0 then begin
  for Index:=0 to CountMeshTriangleContactQueueItems-1 do begin
   MeshTriangleContactQueueItem:=@MeshTriangleContactQueueItems[Index];
   if not HasDuplicateContact(MeshTriangleContactQueueItem^.MeshContactPair.RigidBodyConvex,
                              MeshTriangleContactQueueItem^.MeshContactPair.RigidBodyMesh,
                              MeshTriangleContactQueueItem^.MeshContactPair.ShapeConvex,
                              MeshTriangleContactQueueItem^.MeshContactPair.ShapeMesh,
                              MeshTriangleContactQueueItem^.TriangleIndex) then begin
    AddConvexContact(MeshTriangleContactQueueItem^.MeshContactPair.RigidBodyConvex,
                     MeshTriangleContactQueueItem^.MeshContactPair.RigidBodyMesh,
                     MeshTriangleContactQueueItem^.MeshContactPair.ShapeConvex,
                     MeshTriangleContactQueueItem^.MeshContactPair.ShapeMesh,
                     MeshTriangleContactQueueItem^.TriangleIndex,
                     MeshTriangleContactQueueItem^.MeshContactPair);
   end;
  end;
  CountMeshTriangleContactQueueItems:=0;
 end;

 inc(Physics.MidPhaseTime,Physics.HighResolutionTimer.GetTime-StartTime);

end;

procedure TKraftContactManager.ProcessContactPair(const ContactPair:PKraftContactPair;const ThreadIndex:longint=0);
begin
 ContactPair^.DetectCollisions(self,Physics.TriangleShapes[ThreadIndex],ThreadIndex);
end;

procedure TKraftContactManager.ProcessContactPairJob(const JobIndex,ThreadIndex:longint);
begin
 ProcessContactPair(ActiveContactPairs[JobIndex],ThreadIndex);
end;

procedure TKraftContactManager.DoNarrowPhase;
var ActiveContactPairIndex:longint;
    ContactPair,NextContactPair:PKraftContactPair;
    MeshContactPair,NextMeshContactPair:TKraftMeshContactPair;
    ShapeA,ShapeB:TKraftShape;
    RigidBodyA,RigidBodyB:TKraftRigidBody;
    StartTime:int64;
    Flags:TKraftContactFlags;
begin

 StartTime:=Physics.HighResolutionTimer.GetTime;

 CountActiveContactPairs:=0;

 ContactPair:=ContactPairFirst;

 while assigned(ContactPair) do begin

  ShapeA:=ContactPair^.Shapes[0];
  ShapeB:=ContactPair^.Shapes[1];

  RigidBodyA:=ContactPair^.RigidBodies[0];
  RigidBodyB:=ContactPair^.RigidBodies[1];

  if kcfFiltered in ContactPair^.Flags then begin
   if (not RigidBodyA.CanCollideWith(RigidBodyB)) or (assigned(OnCanCollide) and not OnCanCollide(ShapeA,ShapeB)) then begin
    if (ContactPair^.Flags*[kcfColliding,kcfWasColliding])<>[] then begin
     if (ContactPair^.Flags*[kcfColliding,kcfWasColliding])=[kcfColliding] then begin
      if assigned(OnContactBegin) then begin
       OnContactBegin(ContactPair);
      end;
      if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactBegin) then begin
       ContactPair^.Shapes[0].OnContactBegin(ContactPair,ContactPair^.Shapes[1]);
      end;
      if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactBegin) then begin
       ContactPair^.Shapes[1].OnContactBegin(ContactPair,ContactPair^.Shapes[0]);
      end;
     end;
     if assigned(OnContactEnd) then begin
      OnContactEnd(ContactPair);
     end;
     if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactEnd) then begin
      ContactPair^.Shapes[0].OnContactEnd(ContactPair,ContactPair^.Shapes[1]);
     end;
     if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactEnd) then begin
      ContactPair^.Shapes[1].OnContactEnd(ContactPair,ContactPair^.Shapes[0]);
     end;
    end;
    NextContactPair:=ContactPair^.Next;
    RemoveContact(ContactPair);
    ContactPair:=NextContactPair;
    continue;
   end;
   ContactPair^.Flags:=ContactPair^.Flags-[kcfFiltered];
  end;

  if ((RigidBodyA.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive]) and
     ((RigidBodyB.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive]) then begin
   ContactPair:=ContactPair^.Next;
   continue;
  end;

  if not AABBIntersect(ShapeA.WorldAABB,ShapeB.WorldAABB) then begin
   if (ContactPair^.Flags*[kcfColliding,kcfWasColliding])<>[] then begin
    if (ContactPair^.Flags*[kcfColliding,kcfWasColliding])=[kcfColliding] then begin
     if assigned(OnContactBegin) then begin
      OnContactBegin(ContactPair);
     end;
     if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactBegin) then begin
      ContactPair^.Shapes[0].OnContactBegin(ContactPair,ContactPair^.Shapes[1]);
     end;
     if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactBegin) then begin
      ContactPair^.Shapes[1].OnContactBegin(ContactPair,ContactPair^.Shapes[0]);
     end;
    end;
    if assigned(OnContactEnd) then begin
     OnContactEnd(ContactPair);
    end;
    if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactEnd) then begin
     ContactPair^.Shapes[0].OnContactEnd(ContactPair,ContactPair^.Shapes[1]);
    end;
    if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactEnd) then begin
     ContactPair^.Shapes[1].OnContactEnd(ContactPair,ContactPair^.Shapes[0]);
    end;
   end;
   NextContactPair:=ContactPair^.Next;
   RemoveContact(ContactPair);
   ContactPair:=NextContactPair;
   continue;
  end;

  if assigned(ContactPair^.MeshContactPair) and (ContactPair^.ElementIndex>=0) then begin
   if not AABBIntersect(TKraftShapeMesh(ContactPair^.MeshContactPair.ShapeMesh).Mesh.Triangles[ContactPair^.ElementIndex].AABB,
                                                ContactPair^.MeshContactPair.ConvexAABBInMeshLocalSpace) then begin
    if (ContactPair^.Flags*[kcfColliding,kcfWasColliding])<>[] then begin
     if (ContactPair^.Flags*[kcfColliding,kcfWasColliding])=[kcfColliding] then begin
      if assigned(OnContactBegin) then begin
       OnContactBegin(ContactPair);
      end;
      if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactBegin) then begin
       ContactPair^.Shapes[0].OnContactBegin(ContactPair,ContactPair^.MeshContactPair.ShapeMesh);
      end;
      if assigned(ContactPair^.MeshContactPair.ShapeMesh) and assigned(ContactPair^.MeshContactPair.ShapeMesh.OnContactBegin) then begin
       ContactPair^.Shapes[1].OnContactBegin(ContactPair,ContactPair^.Shapes[0]);
      end;
     end;
     if assigned(OnContactEnd) then begin
      OnContactEnd(ContactPair);
     end;
     if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactEnd) then begin
      ContactPair^.Shapes[0].OnContactEnd(ContactPair,ContactPair^.MeshContactPair.ShapeMesh);
     end;
     if assigned(ContactPair^.MeshContactPair.ShapeMesh) and assigned(ContactPair^.MeshContactPair.ShapeMesh.OnContactEnd) then begin
      ContactPair^.MeshContactPair.ShapeMesh.OnContactEnd(ContactPair,ContactPair^.Shapes[0]);
     end;
    end;
    NextContactPair:=ContactPair^.Next;
    RemoveContact(ContactPair);
    ContactPair:=NextContactPair;
    continue;
   end;
  end;

  ActiveContactPairIndex:=CountActiveContactPairs;
  inc(CountActiveContactPairs);
  if CountActiveContactPairs>length(ActiveContactPairs) then begin
   SetLength(ActiveContactPairs,CountActiveContactPairs*2);
  end;
  ActiveContactPairs[ActiveContactPairIndex]:=ContactPair;

  ContactPair:=ContactPair^.Next;

 end;

 CountRemainActiveContactPairsToDo:=CountActiveContactPairs;

 if assigned(Physics.JobManager) then begin
  Physics.JobManager.OnProcessJob:=ProcessContactPairJob;
  Physics.JobManager.CountRemainJobs:=CountActiveContactPairs;
  Physics.JobManager.ProcessJobs;
 end else begin
  for ActiveContactPairIndex:=0 to CountActiveContactPairs-1 do begin
   ProcessContactPair(ActiveContactPairs[ActiveContactPairIndex],0);
  end;
 end;

 for ActiveContactPairIndex:=0 to CountActiveContactPairs-1 do begin
  ContactPair:=ActiveContactPairs[ActiveContactPairIndex];
  Flags:=ContactPair^.Flags*[kcfColliding,kcfWasColliding];
  if Flags=[kcfColliding] then begin
   if assigned(OnContactBegin) then begin
    OnContactBegin(ContactPair);
   end;
   if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactBegin) then begin
    ContactPair^.Shapes[0].OnContactBegin(ContactPair,ContactPair^.Shapes[1]);
   end;
   if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactBegin) then begin
    ContactPair^.Shapes[1].OnContactBegin(ContactPair,ContactPair^.Shapes[0]);
   end;
  end else if Flags=[kcfWasColliding] then begin
   if assigned(OnContactEnd) then begin
    OnContactEnd(ContactPair);
   end;
   if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactEnd) then begin
    ContactPair^.Shapes[0].OnContactEnd(ContactPair,ContactPair^.Shapes[1]);
   end;
   if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactEnd) then begin
    ContactPair^.Shapes[1].OnContactEnd(ContactPair,ContactPair^.Shapes[0]);
   end;
  end else if Flags=[kcfColliding,kcfWasColliding] then begin
   if assigned(OnContactStay) then begin
    OnContactStay(ContactPair);
   end;
   if assigned(ContactPair^.Shapes[0]) and assigned(ContactPair^.Shapes[0].OnContactStay) then begin
    ContactPair^.Shapes[0].OnContactStay(ContactPair,ContactPair^.Shapes[1]);
   end;
   if assigned(ContactPair^.Shapes[1]) and assigned(ContactPair^.Shapes[1].OnContactStay) then begin
    ContactPair^.Shapes[1].OnContactStay(ContactPair,ContactPair^.Shapes[0]);
   end;
  end;
 end;

 MeshContactPair:=MeshContactPairFirst;
 while assigned(MeshContactPair) do begin

  ShapeA:=MeshContactPair.ShapeConvex;
  ShapeB:=MeshContactPair.ShapeMesh;

  RigidBodyA:=MeshContactPair.RigidBodyConvex;
  RigidBodyB:=MeshContactPair.RigidBodyMesh;

  if kcfFiltered in MeshContactPair.Flags then begin
   if (not RigidBodyA.CanCollideWith(RigidBodyB)) or (assigned(OnCanCollide) and not OnCanCollide(ShapeA,ShapeB)) then begin
    NextMeshContactPair:=MeshContactPair.Next;
    RemoveMeshContact(MeshContactPair);
    MeshContactPair:=NextMeshContactPair;
    continue;
   end;
   MeshContactPair.Flags:=MeshContactPair.Flags-[kcfFiltered];
  end;

  if ((RigidBodyA.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive]) and
     ((RigidBodyB.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive]) then begin
   MeshContactPair:=MeshContactPair.Next;
   continue;
  end;

  if not AABBIntersect(ShapeA.WorldAABB,ShapeB.WorldAABB) then begin
   NextMeshContactPair:=MeshContactPair.Next;
   RemoveMeshContact(MeshContactPair);
   MeshContactPair:=NextMeshContactPair;
   continue;
  end;

  MeshContactPair:=MeshContactPair.Next;

 end;

 inc(Physics.NarrowPhaseTime,Physics.HighResolutionTimer.GetTime-StartTime);

end;

{$ifdef DebugDraw}
procedure TKraftContactManager.DebugDraw(const CameraMatrix:TKraftMatrix4x4);
var i,j:longint;
    ContactPair:PKraftContactPair;
    ContactManifold:PKraftContactManifold;
    Contact:PKraftContact;
    SolverContact:PKraftSolverContact;
    SolverContactManifold:TKraftSolverContactManifold;
    f:TKraftScalar;
begin

 glPushMatrix;
 glMatrixMode(GL_MODELVIEW);

{$ifdef UseDouble}
 glLoadMatrixd(pointer(@CameraMatrix));
{$else}
 glLoadMatrixf(pointer(@CameraMatrix));
{$endif}

 ContactPair:=ContactPairFirst;

 while assigned(ContactPair) do begin

  if kcfColliding in ContactPair^.Flags then begin

   ContactManifold:=@ContactPair^.Manifold;
                                                              
   ContactPair^.GetSolverContactManifold(SolverContactManifold,ContactPair^.RigidBodies[0].WorldTransform,ContactPair^.RigidBodies[1].WorldTransform,false);

   for i:=0 to ContactManifold^.CountContacts-1 do begin

    SolverContact:=@SolverContactManifold.Contacts[i];

    Contact:=@ContactManifold.Contacts[i];

    f:=(1024-Min(Max(Contact^.WarmStartState,0),1024))/1024.0;

    if krbfAwake in ContactPair^.Shapes[0].RigidBody.Flags then begin
     glColor4f(1.0-f,f,f,1.0);
    end else begin
     glColor4f(1.0,1.0,0.0,1.0);
    end;
    glBegin(GL_POINTS);
{$ifdef UseDouble}
    glVertex3dv(@SolverContact^.Point);
{$else}
    glVertex3fv(@SolverContact^.Point);
{$endif}
    glEnd;

    if krbfAwake in ContactPair^.Shapes[0].RigidBody.Flags then begin
     glColor4f(1.0,1.0,1.0,1.0);
    end else begin
     glColor4f(0.2,0.2,0.2,1.0);
    end;
    glBegin(GL_LINES);
    glVertex3fv(@SolverContact^.Point);
    glVertex3f(SolverContact^.Point.x+(SolverContactManifold.Normal.x*SolverContact^.Separation),
               SolverContact^.Point.y+(SolverContactManifold.Normal.y*SolverContact^.Separation),
               SolverContact^.Point.z+(SolverContactManifold.Normal.z*SolverContact^.Separation));
    glEnd;

   end;

  end;

  ContactPair:=ContactPair^.Next;

 end;

 glLineWidth(2);
 glBegin(GL_LINES);
 for i:=0 to CountDebugConvexHullVertexLists-1 do begin
{$ifdef UseDouble}
  glColor4dv(@DebugConvexHullVertexLists[i].Color);
  for j:=0 to DebugConvexHullVertexLists[i].Count-1 do begin
   if j=0 then begin
    glVertex3dv(@DebugConvexHullVertexLists[i].Vertices[DebugConvexHullVertexLists[i].Count-1]);
   end else begin
    glVertex3dv(@DebugConvexHullVertexLists[i].Vertices[j-1]);
   end;
   glVertex3dv(@DebugConvexHullVertexLists[i].Vertices[j]);
  end;
{$else}
  glColor4fv(@DebugConvexHullVertexLists[i].Color);
  for j:=0 to DebugConvexHullVertexLists[i].Count-1 do begin
   if j=0 then begin
    glVertex3fv(@DebugConvexHullVertexLists[i].Vertices[DebugConvexHullVertexLists[i].Count-1]);
   end else begin
    glVertex3fv(@DebugConvexHullVertexLists[i].Vertices[j-1]);
   end;
   glVertex3fv(@DebugConvexHullVertexLists[i].Vertices[j]);
  end;
{$endif}
 end;
 glEnd;

 glPopMatrix;

end;
{$endif}

function TKraftContactManager.ReduceContacts(const AInputContacts:PKraftContacts;const ACountInputContacts:longint;const AOutputContacts:PKraftContacts):longint;
var Index,MaxPenetrationIndex:longint;
    MaxPenetration,MaxDistance,Distance,MaxArea,Area:TKraftScalar;
    Contact:PKraftContact;
    Contacts:array[0..MAX_CONTACTS-1] of PKraftContact;
begin
 if ACountInputContacts<=0 then begin

  result:=0;

 end else if ACountInputContacts<=MAX_CONTACTS then begin

  result:=ACountInputContacts;

  for Index:=0 to ACountInputContacts-1 do begin
   AOutputContacts^[Index]:=AInputContacts^[Index];
  end;

 end else begin

  result:=MAX_CONTACTS;

  MaxPenetrationIndex:=0;
  MaxPenetration:=AInputContacts^[0].Penetration;
  for Index:=1 to ACountInputContacts-1 do begin
   Contact:=@AInputContacts^[Index];
   if MaxPenetration<Contact^.Penetration then begin
    MaxPenetrationIndex:=Index;
    MaxPenetration:=Contact^.Penetration;
   end;
  end;
  Contacts[0]:=@AInputContacts^[MaxPenetrationIndex];

  Contacts[1]:=nil;
  MaxDistance:=0.0;
  for Index:=0 to ACountInputContacts-1 do begin
   Contact:=@AInputContacts^[Index];
   if Contact<>Contacts[0] then begin
    Distance:=Vector3DistSquared(Contact^.LocalPoints[0],Contacts[0]^.LocalPoints[0]);
    if (not assigned(Contacts[1])) or (MaxDistance<Distance) then begin
     MaxDistance:=Distance;
     Contacts[1]:=Contact;
    end;
   end;
  end;

  Contacts[2]:=nil;              
  MaxArea:=0.0;
  for Index:=0 to ACountInputContacts-1 do begin
   Contact:=@AInputContacts^[Index];
   if (Contact<>Contacts[0]) and (Contact<>Contacts[1]) then begin
    Area:=CalculateAreaFromThreePoints(Contact^.LocalPoints[0],Contacts[0]^.LocalPoints[0],Contacts[1]^.LocalPoints[0]);
    if (not assigned(Contacts[2])) or (MaxArea<Area) then begin
     MaxArea:=Area;
     Contacts[2]:=Contact;
    end;
   end;
  end;

  Contacts[3]:=nil;
  MaxArea:=0.0;
  for Index:=0 to ACountInputContacts-1 do begin
   Contact:=@AInputContacts^[Index];
   if (Contact<>Contacts[0]) and (Contact<>Contacts[1]) and (Contact<>Contacts[2]) then begin
    Area:=CalculateAreaFromFourPoints(Contact^.LocalPoints[0],Contacts[0]^.LocalPoints[0],Contacts[1]^.LocalPoints[0],Contacts[2]^.LocalPoints[0]);
    if (not assigned(Contacts[3])) or (MaxArea<Area) then begin
     MaxArea:=Area;
     Contacts[3]:=Contact;
    end;
   end;
  end;

  for Index:=0 to MAX_CONTACTS-1 do begin
   AOutputContacts^[Index]:=Contacts[Index]^;
  end;

 end;
end;

function TKraftContactManager.GetMaximizedAreaReducedContactIndices(const AInputContactPositions:PPKraftVector3s;const ACountInputContactPositions:longint;var AOutputContactIndices:TKraftContactIndices):longint;
var Index,StartIndex:longint;
    MaxDistance,Distance,MaxArea,Area:TKraftScalar;
    Position:PKraftVector3;
    Positions:array[0..MAX_CONTACTS-1] of PKraftVector3;
    Contacts:array[0..MAX_CONTACTS-1] of longint;
begin
 if ACountInputContactPositions<=0 then begin

  result:=0;

 end else if ACountInputContactPositions<=MAX_CONTACTS then begin

  result:=ACountInputContactPositions;

  for Index:=0 to ACountInputContactPositions-1 do begin
   AOutputContactIndices[Index]:=Index;
  end;

 end else begin

  result:=MAX_CONTACTS-1;

  StartIndex:=0;
  Positions[0]:=AInputContactPositions^[StartIndex];
  for Index:=1 to ACountInputContactPositions-1 do begin
   Position:=AInputContactPositions^[Index];
   if (Position^.x<Positions[0]^.x) or (Position^.y<Positions[0]^.y) or (Position^.z<Positions[0]^.z) then begin
    StartIndex:=Index;
    Positions[0]:=AInputContactPositions^[Index];
   end;
  end;
  Contacts[0]:=StartIndex;

  Contacts[1]:=-1;
  MaxDistance:=0.0;
  for Index:=0 to ACountInputContactPositions-1 do begin
   Position:=AInputContactPositions^[Index];
   if Index<>Contacts[0] then begin
    Distance:=Vector3DistSquared(Position^,Positions[0]^);
    if (Contacts[1]<0) or (MaxDistance<Distance) then begin
     MaxDistance:=Distance;
     Contacts[1]:=Index;
    end;
   end;
  end;
  Positions[1]:=AInputContactPositions^[Contacts[1]];

  Contacts[2]:=-1;
  MaxArea:=0.0;
  for Index:=0 to ACountInputContactPositions-1 do begin
   Position:=AInputContactPositions^[Index];
   if (Index<>Contacts[0]) and (Index<>Contacts[1]) then begin
    Area:=CalculateAreaFromThreePoints(Position^,Positions[0]^,Positions[1]^);
    if (Contacts[2]<0) or (MaxArea<Area) then begin
     MaxArea:=Area;
     Contacts[2]:=Index;
    end;
   end;
  end;
  Positions[2]:=AInputContactPositions^[Contacts[2]];

  Contacts[3]:=-1;
  MaxArea:=0.0;
  for Index:=0 to ACountInputContactPositions-1 do begin
   Position:=AInputContactPositions^[Index];
   if (Index<>Contacts[0]) and (Index<>Contacts[1]) and (Index<>Contacts[2]) then begin
    Area:=CalculateAreaFromFourPoints(Position^,Positions[0]^,Positions[1]^,Positions[2]^);
    if (Contacts[3]<0) or (MaxArea<Area) then begin
     MaxArea:=Area;
     Contacts[3]:=Index;
    end;
   end;
  end;

  for Index:=0 to MAX_CONTACTS-1 do begin
   AOutputContactIndices[Index]:=Contacts[Index];
  end;

 end;
end;

constructor TKraftBroadPhase.Create(const APhysics:TKraft);
begin
 inherited Create;

 Physics:=APhysics;

 ContactPairs:=nil;
 SetLength(ContactPairs,4096);
 CountContactPairs:=0;

 StaticMoveBuffer:=nil;
 SetLength(StaticMoveBuffer,64);
 StaticMoveBufferSize:=0;

 SleepingMoveBuffer:=nil;
 SetLength(SleepingMoveBuffer,64);
 SleepingMoveBufferSize:=0;

 DynamicMoveBuffer:=nil;
 SetLength(DynamicMoveBuffer,64);
 DynamicMoveBufferSize:=0;

 KinematicMoveBuffer:=nil;
 SetLength(KinematicMoveBuffer,64);
 KinematicMoveBufferSize:=0;

end;

destructor TKraftBroadPhase.Destroy;
begin
 SetLength(ContactPairs,0);
 SetLength(StaticMoveBuffer,0);
 SetLength(SleepingMoveBuffer,0);
 SetLength(DynamicMoveBuffer,0);
 SetLength(KinematicMoveBuffer,0);
 inherited Destroy;
end;

function CompareContactPairs(const a,b:pointer):longint;
begin
 result:=PtrInt(PKraftBroadPhaseContactPair(a)^[0])-PtrInt(PKraftBroadPhaseContactPair(b)^[0]);
 if result=0 then begin
  result:=PtrInt(PKraftBroadPhaseContactPair(a)^[1])-PtrInt(PKraftBroadPhaseContactPair(b)^[1]);
 end;
end;

procedure TKraftBroadPhase.UpdatePairs;
 procedure AddPair(ShapeA,ShapeB:TKraftShape); {$ifdef caninline}inline;{$endif}
 var TempShape:TKraftShape;
     Index:longint;
     ContactPair:PKraftBroadPhaseContactPair;
 begin
  if ShapeA<>ShapeB then begin
   if (ShapeA.ShapeType>ShapeB.ShapeType) or ((ShapeA.ShapeType=ShapeB.ShapeType) and (ptruint(ShapeA)>ptruint(ShapeB))) then begin
    TempShape:=ShapeA;
    ShapeA:=ShapeB;
    ShapeB:=TempShape;
   end;
   Index:=CountContactPairs;
   inc(CountContactPairs);
   if CountContactPairs>length(ContactPairs) then begin
    SetLength(ContactPairs,CountContactPairs*2);
   end;
   ContactPair:=@ContactPairs[Index];
   ContactPair[0]:=ShapeA;
   ContactPair[1]:=ShapeB;
  end;
 end;
 procedure QueryShapeWithTree(Shape:TKraftShape;AABBTree:TKraftDynamicAABBTree);
 var ShapeAABB:PKraftAABB;
     LocalStack:PKraftDynamicAABBTreeLongintArray;
     LocalStackPointer,NodeID:longint;
     Node:PKraftDynamicAABBTreeNode;
     OtherShape:TKraftShape;
 begin
  if assigned(Shape) and assigned(AABBTree) then begin
   ShapeAABB:=@Shape.WorldAABB;
   if AABBTree.Root>=0 then begin
    LocalStack:=AABBTree.Stack;
    LocalStack^[0]:=AABBTree.Root;
    LocalStackPointer:=1;
    while LocalStackPointer>0 do begin
     dec(LocalStackPointer);
     NodeID:=LocalStack^[LocalStackPointer];
     if NodeID>=0 then begin
      Node:=@AABBTree.Nodes[NodeID];
      if AABBIntersect(Node^.AABB,ShapeAABB^) then begin
       if Node^.Children[0]<0 then begin
        OtherShape:=Node^.UserData;
        if assigned(OtherShape) and (Shape<>OtherShape) then begin
         AddPair(Shape,OtherShape);
        end;
       end else begin
        if AABBTree.StackCapacity<=(LocalStackPointer+2) then begin
         AABBTree.StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+2);
         ReallocMem(AABBTree.Stack,AABBTree.StackCapacity*SizeOf(longint));
         LocalStack:=AABBTree.Stack;
        end;
        LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
        LocalStack^[LocalStackPointer+1]:=Node^.Children[1];
        inc(LocalStackPointer,2);
       end;
      end;
     end;
    end;
   end;
  end;
 end;
var i:longint;
    Shape:TKraftShape;
    ContactPair,OtherContactPair:PKraftBroadPhaseContactPair;
begin

 CountContactPairs:=0;

 for i:=0 to StaticMoveBufferSize-1 do begin
  if StaticMoveBuffer[i]>=0 then begin
   Shape:=Physics.StaticAABBTree.Nodes[StaticMoveBuffer[i]].UserData;
   if assigned(Shape) then begin
    QueryShapeWithTree(Shape,Physics.SleepingAABBTree);
    QueryShapeWithTree(Shape,Physics.DynamicAABBTree);
   end;
  end;
 end;
 StaticMoveBufferSize:=0;

 for i:=0 to SleepingMoveBufferSize-1 do begin
  if SleepingMoveBuffer[i]>=0 then begin
   Shape:=Physics.SleepingAABBTree.Nodes[SleepingMoveBuffer[i]].UserData;
   if assigned(Shape) then begin
    QueryShapeWithTree(Shape,Physics.StaticAABBTree);
    QueryShapeWithTree(Shape,Physics.SleepingAABBTree);
    QueryShapeWithTree(Shape,Physics.SleepingAABBTree);
    QueryShapeWithTree(Shape,Physics.KinematicAABBTree);
   end;
  end;
 end;
 SleepingMoveBufferSize:=0;

 for i:=0 to DynamicMoveBufferSize-1 do begin
  if DynamicMoveBuffer[i]>=0 then begin
   Shape:=Physics.DynamicAABBTree.Nodes[DynamicMoveBuffer[i]].UserData;
   if assigned(Shape) then begin
    QueryShapeWithTree(Shape,Physics.StaticAABBTree);
    QueryShapeWithTree(Shape,Physics.SleepingAABBTree);
    QueryShapeWithTree(Shape,Physics.DynamicAABBTree);
    QueryShapeWithTree(Shape,Physics.KinematicAABBTree);
   end;
  end;
 end;
 DynamicMoveBufferSize:=0;

 for i:=0 to KinematicMoveBufferSize-1 do begin
  if KinematicMoveBuffer[i]>=0 then begin
   Shape:=Physics.KinematicAABBTree.Nodes[KinematicMoveBuffer[i]].UserData;
   if assigned(Shape) then begin
    QueryShapeWithTree(Shape,Physics.SleepingAABBTree);
    QueryShapeWithTree(Shape,Physics.DynamicAABBTree);
   end;
  end;
 end;
 KinematicMoveBufferSize:=0;

 if CountContactPairs>0 then begin

  // Sort pairs to expose duplicates
  DirectIntroSort(@ContactPairs[0],0,CountContactPairs-1,SizeOf(TKraftBroadPhaseContactPair),CompareContactPairs);

  // Queue manifolds for solving
  i:=0;
  while i<CountContactPairs do begin

   ContactPair:=@ContactPairs[i];
   inc(i);

   // Add contact pair to contact manager
   Physics.ContactManager.AddContact(ContactPair^[0],ContactPair^[1]);

   // Skip duplicate pairs until we find a unique pair
   while i<CountContactPairs do begin
    OtherContactPair:=@ContactPairs[i];
    if (ContactPair^[0]<>OtherContactPair^[0]) or (ContactPair^[1]<>OtherContactPair^[1]) then begin
     break;
    end;
    inc(i);
   end;

  end;

 end;

end;

procedure TKraftBroadPhase.StaticBufferMove(ProxyID:longint);
var Index:longint;
begin
 Index:=StaticMoveBufferSize;
 inc(StaticMoveBufferSize);
 if StaticMoveBufferSize>length(StaticMoveBuffer) then begin
  SetLength(StaticMoveBuffer,StaticMoveBufferSize*2);
 end;
 StaticMoveBuffer[Index]:=ProxyID;
end;

procedure TKraftBroadPhase.SleepingBufferMove(ProxyID:longint);
var Index:longint;
begin
 Index:=SleepingMoveBufferSize;
 inc(SleepingMoveBufferSize);
 if SleepingMoveBufferSize>length(SleepingMoveBuffer) then begin
  SetLength(SleepingMoveBuffer,SleepingMoveBufferSize*2);
 end;
 SleepingMoveBuffer[Index]:=ProxyID;
end;

procedure TKraftBroadPhase.DynamicBufferMove(ProxyID:longint);
var Index:longint;
begin
 Index:=DynamicMoveBufferSize;
 inc(DynamicMoveBufferSize);
 if DynamicMoveBufferSize>length(DynamicMoveBuffer) then begin
  SetLength(DynamicMoveBuffer,DynamicMoveBufferSize*2);
 end;
 DynamicMoveBuffer[Index]:=ProxyID;
end;

procedure TKraftBroadPhase.KinematicBufferMove(ProxyID:longint);
var Index:longint;
begin
 Index:=KinematicMoveBufferSize;
 inc(KinematicMoveBufferSize);
 if KinematicMoveBufferSize>length(KinematicMoveBuffer) then begin
  SetLength(KinematicMoveBuffer,KinematicMoveBufferSize*2);
 end;
 KinematicMoveBuffer[Index]:=ProxyID;
end;

constructor TKraftRigidBody.Create(const APhysics:TKraft);
begin
 inherited Create;

 Physics:=APhysics;

 Island:=nil;

 IslandIndices:=nil;
 SetLength(IslandIndices,4);

 inc(Physics.CountRigidBodies);

 ID:=Physics.RigidBodyIDCounter;
 inc(Physics.RigidBodyIDCounter);

 RigidBodyType:=krbtUnknown;

 if assigned(Physics.RigidBodyLast) then begin
  Physics.RigidBodyLast.RigidBodyNext:=self;
  RigidBodyPrevious:=Physics.RigidBodyLast;
 end else begin
  Physics.RigidBodyFirst:=self;
  RigidBodyPrevious:=nil;
 end;
 Physics.RigidBodyLast:=self;
 RigidBodyNext:=nil;

 StaticRigidBodyIsOnList:=false;
 StaticRigidBodyPrevious:=nil;
 StaticRigidBodyNext:=nil;

 DynamicRigidBodyIsOnList:=false;
 DynamicRigidBodyPrevious:=nil;
 DynamicRigidBodyNext:=nil;

 KinematicRigidBodyIsOnList:=false;
 KinematicRigidBodyPrevious:=nil;
 KinematicRigidBodyNext:=nil;

 ShapeFirst:=nil;
 ShapeLast:=nil;

 ShapeCount:=0;

 Flags:=[krbfContinuous,krbfAllowSleep,krbfAwake,krbfActive];

{WorldAABB.Min:=Vector3Origin;
 WorldAABB.Max:=Vector3Origin;{}

 WorldDisplacement:=Vector3Origin;

 Sweep.LocalCenter:=Vector3Origin;
 Sweep.c0:=Vector3Origin;
 Sweep.c:=Vector3Origin;
 Sweep.q0:=QuaternionIdentity;
 Sweep.q:=QuaternionIdentity;
 Sweep.Alpha0:=0.0;

 WorldTransform:=Matrix4x4Identity;

 Gravity.x:=0.0;
 Gravity.y:=-9.83;
 Gravity.z:=0.0;

 UserData:=nil;

 NextOnIslandBuildStack:=nil;
 NextStaticRigidBody:=nil;

 BodyInertiaTensor:=Matrix3x3Identity;
 BodyInverseInertiaTensor:=Matrix3x3Identity;

 WorldInertiaTensor:=Matrix3x3Identity;
 WorldInverseInertiaTensor:=Matrix3x3Identity;

 ForcedMass:=0.0;

 Mass:=0.0;
 InverseMass:=0.0;

 LinearVelocity:=Vector3Origin;
 AngularVelocity:=Vector3Origin;

 MaximalLinearVelocity:=0.0;
 MaximalAngularVelocity:=0.0;

 LinearVelocityDamp:=0.1;
 AngularVelocityDamp:=0.1;
 AdditionalDamping:=false;
 AdditionalDamp:=0.005;
 LinearVelocityAdditionalDamp:=0.01;
 AngularVelocityAdditionalDamp:=0.01;
 LinearVelocityAdditionalDampThresholdSqr:=0.01;
 AngularVelocityAdditionalDampThresholdSqr:=0.01;
 
 Force:=Vector3Origin;
 Torque:=Vector3Origin;

 SleepTime:=0.0;

 GravityScale:=1.0;

 EnableGyroscopicForce:=false;

 MaximalGyroscopicForce:=0.0;

 CollisionGroups:=[0];

 CollideWithCollisionGroups:=[low(TKraftRigidBodyCollisionGroup)..high(TKraftRigidBodyCollisionGroup)];

 CountConstraints:=0;

 ConstraintEdgeFirst:=nil;
 ConstraintEdgeLast:=nil;

 ContactPairEdgeFirst:=nil;
 ContactPairEdgeLast:=nil;

 OnPreStep:=nil;
 OnPostStep:=nil;

end;

destructor TKraftRigidBody.Destroy;
var ConstraintEdge,NextConstraintEdge:PKraftConstraintEdge;
    Constraint:TKraftConstraint;
begin

 ConstraintEdge:=ConstraintEdgeFirst;
 while assigned(ConstraintEdge) do begin
  NextConstraintEdge:=ConstraintEdge^.Next;
  Constraint:=ConstraintEdge^.Constraint;
  if assigned(Constraint) then begin
   Constraint.Free;
  end;
  ConstraintEdge:=NextConstraintEdge;
 end;

 CountConstraints:=0;

 while assigned(ShapeLast) do begin
  ShapeLast.Free;
 end;

 Physics.ContactManager.RemoveContactsFromRigidBody(self);

 if assigned(RigidBodyPrevious) then begin
  RigidBodyPrevious.RigidBodyNext:=RigidBodyNext;
 end else if Physics.RigidBodyFirst=self then begin
  Physics.RigidBodyFirst:=RigidBodyNext;
 end;
 if assigned(RigidBodyNext) then begin
  RigidBodyNext.RigidBodyPrevious:=RigidBodyPrevious;
 end else if Physics.RigidBodyLast=self then begin
  Physics.RigidBodyLast:=RigidBodyPrevious;
 end;
 RigidBodyPrevious:=nil;
 RigidBodyNext:=nil;

 if StaticRigidBodyIsOnList then begin
  StaticRigidBodyIsOnList:=false;
  if assigned(StaticRigidBodyPrevious) then begin
   StaticRigidBodyPrevious.StaticRigidBodyNext:=StaticRigidBodyNext;
  end else if Physics.StaticRigidBodyFirst=self then begin
   Physics.StaticRigidBodyFirst:=StaticRigidBodyNext;
  end;
  if assigned(StaticRigidBodyNext) then begin
   StaticRigidBodyNext.StaticRigidBodyPrevious:=StaticRigidBodyPrevious;
  end else if Physics.StaticRigidBodyLast=self then begin
   Physics.StaticRigidBodyLast:=StaticRigidBodyPrevious;
  end;
  StaticRigidBodyPrevious:=nil;
  StaticRigidBodyNext:=nil;
 end;

 if DynamicRigidBodyIsOnList then begin
  DynamicRigidBodyIsOnList:=false;
  if assigned(DynamicRigidBodyPrevious) then begin
   DynamicRigidBodyPrevious.DynamicRigidBodyNext:=DynamicRigidBodyNext;
  end else if Physics.DynamicRigidBodyFirst=self then begin
   Physics.DynamicRigidBodyFirst:=DynamicRigidBodyNext;
  end;
  if assigned(DynamicRigidBodyNext) then begin
   DynamicRigidBodyNext.DynamicRigidBodyPrevious:=DynamicRigidBodyPrevious;
  end else if Physics.DynamicRigidBodyLast=self then begin
   Physics.DynamicRigidBodyLast:=DynamicRigidBodyPrevious;
  end;
  DynamicRigidBodyPrevious:=nil;
  DynamicRigidBodyNext:=nil;
 end;

 if KinematicRigidBodyIsOnList then begin
  KinematicRigidBodyIsOnList:=false;
  if assigned(KinematicRigidBodyPrevious) then begin
   KinematicRigidBodyPrevious.KinematicRigidBodyNext:=KinematicRigidBodyNext;
  end else if Physics.KinematicRigidBodyFirst=self then begin
   Physics.KinematicRigidBodyFirst:=KinematicRigidBodyNext;
  end;
  if assigned(KinematicRigidBodyNext) then begin
   KinematicRigidBodyNext.KinematicRigidBodyPrevious:=KinematicRigidBodyPrevious;
  end else if Physics.KinematicRigidBodyLast=self then begin
   Physics.KinematicRigidBodyLast:=KinematicRigidBodyPrevious;
  end;
  KinematicRigidBodyPrevious:=nil;
  KinematicRigidBodyNext:=nil;
 end;

 SetLength(IslandIndices,0);

 RigidBodyType:=krbtUnknown;

 inherited Destroy;
end;

function TKraftRigidBody.SetRigidBodyType(ARigidBodyType:TKraftRigidBodyType):TKraftRigidBody;
var Shape:TKraftShape;
begin

 if RigidBodyType<>ARigidBodyType then begin

  case RigidBodyType of
   krbtStatic:begin

    dec(Physics.StaticRigidBodyCount);

    if StaticRigidBodyIsOnList then begin
     StaticRigidBodyIsOnList:=false;
     if assigned(StaticRigidBodyPrevious) then begin
      StaticRigidBodyPrevious.StaticRigidBodyNext:=StaticRigidBodyNext;
     end else if Physics.StaticRigidBodyFirst=self then begin
      Physics.StaticRigidBodyFirst:=StaticRigidBodyNext;
     end;
     if assigned(StaticRigidBodyNext) then begin
      StaticRigidBodyNext.StaticRigidBodyPrevious:=StaticRigidBodyPrevious;
     end else if Physics.StaticRigidBodyLast=self then begin
      Physics.StaticRigidBodyLast:=StaticRigidBodyPrevious;
     end;
     StaticRigidBodyPrevious:=nil;
     StaticRigidBodyNext:=nil;
    end;

   end;
   krbtDynamic:begin

    dec(Physics.DynamicRigidBodyCount);

    if DynamicRigidBodyIsOnList then begin
     DynamicRigidBodyIsOnList:=false;
     if assigned(DynamicRigidBodyPrevious) then begin
      DynamicRigidBodyPrevious.DynamicRigidBodyNext:=DynamicRigidBodyNext;
     end else if Physics.DynamicRigidBodyFirst=self then begin
      Physics.DynamicRigidBodyFirst:=DynamicRigidBodyNext;
     end;
     if assigned(DynamicRigidBodyNext) then begin
      DynamicRigidBodyNext.DynamicRigidBodyPrevious:=DynamicRigidBodyPrevious;
     end else if Physics.DynamicRigidBodyLast=self then begin
      Physics.DynamicRigidBodyLast:=DynamicRigidBodyPrevious;
     end;
     DynamicRigidBodyPrevious:=nil;
     DynamicRigidBodyNext:=nil;
    end;

   end;
   krbtKinematic:begin

    dec(Physics.KinematicRigidBodyCount);

    if KinematicRigidBodyIsOnList then begin
     KinematicRigidBodyIsOnList:=false;
     if assigned(KinematicRigidBodyPrevious) then begin
      KinematicRigidBodyPrevious.KinematicRigidBodyNext:=KinematicRigidBodyNext;
     end else if Physics.KinematicRigidBodyFirst=self then begin
      Physics.KinematicRigidBodyFirst:=KinematicRigidBodyNext;
     end;
     if assigned(KinematicRigidBodyNext) then begin
      KinematicRigidBodyNext.KinematicRigidBodyPrevious:=KinematicRigidBodyPrevious;
     end else if Physics.KinematicRigidBodyLast=self then begin
      Physics.KinematicRigidBodyLast:=KinematicRigidBodyPrevious;
     end;
     KinematicRigidBodyPrevious:=nil;
     KinematicRigidBodyNext:=nil;
    end;

   end;
  end;

  RigidBodyType:=ARigidBodyType;

  case RigidBodyType of
   krbtStatic:begin

    if assigned(Physics.StaticRigidBodyLast) then begin
     Physics.StaticRigidBodyLast.StaticRigidBodyNext:=self;
     StaticRigidBodyPrevious:=Physics.StaticRigidBodyLast;
    end else begin
     Physics.StaticRigidBodyFirst:=self;
     StaticRigidBodyPrevious:=nil;
    end;
    Physics.StaticRigidBodyLast:=self;
    StaticRigidBodyNext:=nil;
    StaticRigidBodyIsOnList:=true;

    inc(Physics.StaticRigidBodyCount);

   end;
   krbtDynamic:begin

    if assigned(Physics.DynamicRigidBodyLast) then begin
     Physics.DynamicRigidBodyLast.DynamicRigidBodyNext:=self;
     DynamicRigidBodyPrevious:=Physics.DynamicRigidBodyLast;
    end else begin
     Physics.DynamicRigidBodyFirst:=self;
     DynamicRigidBodyPrevious:=nil;
    end;
    Physics.DynamicRigidBodyLast:=self;
    DynamicRigidBodyNext:=nil;
    DynamicRigidBodyIsOnList:=true;

    inc(Physics.DynamicRigidBodyCount);

   end;
   krbtKinematic:begin

    if assigned(Physics.KinematicRigidBodyLast) then begin
     Physics.KinematicRigidBodyLast.KinematicRigidBodyNext:=self;
     KinematicRigidBodyPrevious:=Physics.KinematicRigidBodyLast;
    end else begin
     Physics.KinematicRigidBodyFirst:=self;
     KinematicRigidBodyPrevious:=nil;
    end;
    Physics.KinematicRigidBodyLast:=self;
    KinematicRigidBodyNext:=nil;
    KinematicRigidBodyIsOnList:=true;

    inc(Physics.KinematicRigidBodyCount);

   end;
  end;

  Shape:=ShapeFirst;
  while assigned(Shape) do begin
   Shape.SynchronizeProxies;
   Shape:=Shape.ShapeNext;
  end;

 end;

 result:=self;
end;

function TKraftRigidBody.IsStatic:boolean;
begin
 result:=RigidBodyType=krbtStatic;
end;

function TKraftRigidBody.IsDynamic:boolean;
begin
 result:=RigidBodyType=krbtDynamic;
end;

function TKraftRigidBody.IsKinematic:boolean;
begin
 result:=RigidBodyType=krbtKinematic;
end;

procedure TKraftRigidBody.SynchronizeTransform;
begin
 WorldTransform:=QuaternionToMatrix4x4(Sweep.q);
 PKraftVector3(pointer(@WorldTransform[3,0]))^.xyz:=Vector3Sub(Sweep.c,Vector3TermMatrixMulBasis(Sweep.LocalCenter,WorldTransform)).xyz;
end;

procedure TKraftRigidBody.SynchronizeTransformIncludingShapes;
var Shape:TKraftShape;
begin
 SynchronizeTransform;
 Shape:=ShapeFirst;
 while assigned(Shape) do begin
  Shape.SynchronizeTransform;
  Shape:=Shape.ShapeNext;
 end;
end;

procedure TKraftRigidBody.StoreWorldTransform;
var Shape:TKraftShape;
begin
 Shape:=ShapeFirst;
 while assigned(Shape) do begin
  Shape.StoreWorldTransform;
  Shape:=Shape.ShapeNext;
 end;
end;

procedure TKraftRigidBody.InterpolateWorldTransform(const Alpha:TKraftScalar);
var Shape:TKraftShape;
begin
 Shape:=ShapeFirst;
 while assigned(Shape) do begin
  Shape.InterpolateWorldTransform(Alpha);
  Shape:=Shape.ShapeNext;
 end;
end;

procedure TKraftRigidBody.Advance(Alpha:TKraftScalar);
begin
 SweepAdvance(Sweep,Alpha);
 Sweep.c:=Sweep.c0;
 Sweep.q:=Sweep.q0;
 SynchronizeTransformIncludingShapes;
end;

procedure TKraftRigidBody.UpdateWorldInertiaTensor;
var Orientation:TKraftMatrix3x3;
begin
 if RigidBodyType=krbtDynamic then begin
  Orientation:=QuaternionToMatrix3x3(Sweep.q0);
  WorldInverseInertiaTensor:=Matrix3x3TermMulTranspose(Matrix3x3TermMul(Orientation,BodyInverseInertiaTensor),Orientation);
//WorldInverseInertiaTensor:=Matrix3x3TermMul(Matrix3x3TermMul(Orientation,BodyInverseInertiaTensor),Matrix3x3TermTranspose(Orientation));
  Matrix3x3Inverse(WorldInertiaTensor,WorldInverseInertiaTensor);
 end;
end;

procedure TKraftRigidBody.Finish;
{}procedure CalculateMassData; {$ifdef caninline}inline;{$endif}
 var Shape:TKraftShape;
     TempLocalCenter,a,b,c:TKraftVector3;
     Identity:TKraftMatrix3x3;
 begin

  FillChar(BodyInertiaTensor,SizeOf(TKraftMatrix3x3),AnsiChar(#0));
  FillChar(BodyInverseInertiaTensor,SizeOf(TKraftMatrix3x3),AnsiChar(#0));

  FillChar(WorldInertiaTensor,SizeOf(TKraftMatrix3x3),AnsiChar(#0));
  FillChar(WorldInverseInertiaTensor,SizeOf(TKraftMatrix3x3),AnsiChar(#0));

  Mass:=0.0;
  InverseMass:=0.0;

  if RigidBodyType<>krbtDynamic then begin

   Sweep.LocalCenter:=Vector3Origin;
   Sweep.c0.x:=WorldTransform[3,0];
   Sweep.c0.y:=WorldTransform[3,1];
   Sweep.c0.z:=WorldTransform[3,2];
   Sweep.c:=Sweep.c0;

  end else begin

   TempLocalCenter:=Vector3Origin;

   Shape:=ShapeFirst;
   while assigned(Shape) do begin
    if Shape is TKraftShapePlane then begin
     raise EKraftShapeTypeOnlyForStaticRigidBody.Create('Plane shapes are allowed only at static rigidbodies');
    end else if Shape is TKraftShapeTriangle then begin
     raise EKraftShapeTypeOnlyForStaticRigidBody.Create('Triangle shapes are allowed only at static rigidbodies');
    end else if Shape is TKraftShapeMesh then begin
     raise EKraftShapeTypeOnlyForStaticRigidBody.Create('Mesh shapes are allowed only at static rigidbodies');
    end;
    if Shape.Density>EPSILON then begin
     Mass:=Mass+Shape.MassData.Mass;
     Matrix3x3Add(BodyInertiaTensor,Shape.MassData.Inertia);
     TempLocalCenter:=Vector3Add(TempLocalCenter,Vector3ScalarMul(Shape.MassData.Center,Shape.MassData.Mass));
    end;
    Shape:=Shape.ShapeNext;
   end;

   if Mass>EPSILON then begin

    InverseMass:=1.0/Mass;

    TempLocalCenter.x:=TempLocalCenter.x/Mass;
    TempLocalCenter.y:=TempLocalCenter.y/Mass;
    TempLocalCenter.z:=TempLocalCenter.z/Mass;

    Identity:=Matrix3x3Identity;

    Matrix3x3ScalarMul(Identity,Vector3Dot(TempLocalCenter,TempLocalCenter));
    a:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.x);
    b:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.y);
    c:=Vector3ScalarMul(TempLocalCenter,TempLocalCenter.z);
    Identity[0,0]:=(Identity[0,0]-a.x)*Mass;
    Identity[0,1]:=(Identity[0,1]-a.y)*Mass;
    Identity[0,2]:=(Identity[0,2]-a.z)*Mass;
    Identity[0,0]:=(Identity[1,0]-b.x)*Mass;
    Identity[1,1]:=(Identity[1,1]-b.y)*Mass;
    Identity[1,2]:=(Identity[1,2]-b.z)*Mass;
    Identity[2,0]:=(Identity[2,0]-c.x)*Mass;
    Identity[2,1]:=(Identity[2,1]-c.y)*Mass;
    Identity[2,2]:=(Identity[2,2]-c.z)*Mass;

    Matrix3x3Sub(BodyInertiaTensor,Identity);

    BodyInertiaTensor[1,0]:=BodyInertiaTensor[0,1];
    BodyInertiaTensor[2,0]:=BodyInertiaTensor[0,2];
    BodyInertiaTensor[2,1]:=BodyInertiaTensor[1,2];

    Matrix3x3Inverse(BodyInverseInertiaTensor,BodyInertiaTensor);

    if (Flags*[krbfLockAxisX,krbfLockAxisY,krbfLockAxisZ])<>[] then begin

     if krbfLockAxisX in Flags then begin
      BodyInverseInertiaTensor[0,0]:=0.0;
      BodyInverseInertiaTensor[0,1]:=0.0;
      BodyInverseInertiaTensor[0,2]:=0.0;
     end;

     if krbfLockAxisY in Flags then begin
      BodyInverseInertiaTensor[1,0]:=0.0;
      BodyInverseInertiaTensor[1,1]:=0.0;
      BodyInverseInertiaTensor[1,2]:=0.0;
     end;

     if krbfLockAxisZ in Flags then begin
      BodyInverseInertiaTensor[2,0]:=0.0;
      BodyInverseInertiaTensor[2,1]:=0.0;
      BodyInverseInertiaTensor[2,2]:=0.0;
     end;

     Matrix3x3Inverse(BodyInertiaTensor,BodyInverseInertiaTensor);

    end;

    if ForcedMass>EPSILON then begin
     Matrix3x3ScalarMul(BodyInertiaTensor,ForcedMass/Mass);
     Mass:=ForcedMass;
     InverseMass:=1.0/Mass;
    end;

   end else begin

    InverseMass:=1.0;

   end;

   Sweep.LocalCenter:=TempLocalCenter;
   Sweep.c0:=Vector3TermMatrixMul(TempLocalCenter,WorldTransform);
   Sweep.c:=Sweep.c0;

  end;

 end;
var Shape:TKraftShape;
begin

 Shape:=ShapeFirst;
 while assigned(Shape) do begin
  Shape.Finish;
  Shape:=Shape.ShapeNext;
 end;

 CalculateMassData;

 SynchronizeTransform;

 SynchronizeProxies;

 UpdateWorldInertiaTensor;

end;

procedure TKraftRigidBody.SynchronizeProxies;
var Shape:TKraftShape;
    NewTransform:TKraftMatrix4x4;
begin
 NewTransform:=QuaternionToMatrix4x4(Sweep.q0);
 PKraftVector3(pointer(@NewTransform[3,0]))^.xyz:=Vector3Sub(Sweep.c0,Vector3TermMatrixMulBasis(Sweep.LocalCenter,NewTransform)).xyz;
 WorldDisplacement:=Vector3Sub(PKraftVector3(pointer(@NewTransform[3,0]))^,PKraftVector3(pointer(@WorldTransform[3,0]))^);
 Shape:=ShapeFirst;
 while assigned(Shape) do begin
  Shape.SynchronizeProxies;
  Shape:=Shape.ShapeNext;
 end;
end;

procedure TKraftRigidBody.Refilter;
var ContactPairEdge:PKraftContactPairEdge;
    ContactPair:PKraftContactPair;
begin
 ContactPairEdge:=ContactPairEdgeFirst;
 while assigned(ContactPairEdge) do begin
  ContactPair:=ContactPairEdge^.ContactPair;
  if assigned(ContactPair) then begin
   ContactPair^.Flags:=ContactPair^.Flags+[kcfFiltered];
   if assigned(ContactPair^.MeshContactPair) then begin
    ContactPair^.MeshContactPair.Flags:=ContactPair^.MeshContactPair.Flags+[kcfFiltered];
   end;
  end;
  ContactPairEdge:=ContactPairEdge^.Next;
 end;
end;

function TKraftRigidBody.CanCollideWith(OtherRigidBody:TKraftRigidBody):boolean;
var ConstraintEdge:PKraftConstraintEdge;
    Constraint:TKraftConstraint;
begin
 if (assigned(OtherRigidBody) and
    (self<>OtherRigidBody)) and // Don't collide with itself
    (((RigidBodyType=krbtDynamic) or // Every collision must have at least one dynamic body involved
      (OtherRigidBody.RigidBodyType=krbtDynamic)) and
     (((CollisionGroups*OtherRigidBody.CollideWithCollisionGroups)<>[]) or
      ((OtherRigidBody.CollisionGroups*CollideWithCollisionGroups)<>[])
     )
    ) then begin
  ConstraintEdge:=ConstraintEdgeFirst;
  while assigned(ConstraintEdge) do begin
   Constraint:=ConstraintEdge^.Constraint;     
   if (assigned(Constraint) and not (kcfCollideConnected in Constraint.Flags)) and (ConstraintEdge^.OtherRigidBody=OtherRigidBody) then begin
    result:=false;
    exit;
   end;
   ConstraintEdge:=ConstraintEdge^.Next;
  end;
  result:=true;
 end else begin
  result:=false;
 end;
end;

procedure TKraftRigidBody.SetToAwake;
var ConstraintEdge:PKraftConstraintEdge;
begin
 if not (krbfAwake in Flags) then begin
  Include(Flags,krbfAwake);
  SleepTime:=0.0;
  WorldDisplacement:=Vector3Origin;
  ConstraintEdge:=ConstraintEdgeFirst;
  while assigned(ConstraintEdge) do begin
   if assigned(ConstraintEdge^.OtherRigidBody) and (ConstraintEdge^.OtherRigidBody<>self) then begin
    ConstraintEdge^.OtherRigidBody.SetToAwake;
   end;
   ConstraintEdge:=ConstraintEdge^.Next;
  end;
 end;
end;

procedure TKraftRigidBody.SetToSleep;
begin
 Exclude(Flags,krbfAwake);
 SleepTime:=0.0;
 LinearVelocity:=Vector3Origin;
 AngularVelocity:=Vector3Origin;
 Force:=Vector3Origin;
 Torque:=Vector3Origin;
 WorldDisplacement:=Vector3Origin;
end;

procedure TKraftRigidBody.SetWorldTransformation(const AWorldTransformation:TKraftMatrix4x4);
begin
 WorldTransform:=AWorldTransformation;
 UpdateWorldInertiaTensor;
 Sweep.c0:=Vector3TermMatrixMul(Sweep.LocalCenter,WorldTransform);
 Sweep.c:=Sweep.c0;
 Sweep.q0:=QuaternionFromMatrix4x4(WorldTransform);
 Sweep.q:=Sweep.q0;
 SynchronizeProxies;
 SetToAwake;
end;

procedure TKraftRigidBody.SetWorldPosition(const AWorldPosition:TKraftVector3);
begin
 PKraftVector3(pointer(@WorldTransform[3,0]))^.xyz:=AWorldPosition.xyz;
 Sweep.c0:=Vector3Add(AWorldPosition,Vector3TermMatrixMulBasis(Sweep.LocalCenter,WorldTransform));
 Sweep.c:=Sweep.c0;
 SynchronizeProxies;
 SetToAwake;
end;

procedure TKraftRigidBody.SetOrientation(const AOrientation:TKraftMatrix3x3);
begin
 PKraftVector3(pointer(@WorldTransform[0,0]))^.xyz:=PKraftVector3(pointer(@AOrientation[0,0]))^.xyz;
 PKraftVector3(pointer(@WorldTransform[1,0]))^.xyz:=PKraftVector3(pointer(@AOrientation[1,0]))^.xyz;
 PKraftVector3(pointer(@WorldTransform[2,0]))^.xyz:=PKraftVector3(pointer(@AOrientation[2,0]))^.xyz;
 UpdateWorldInertiaTensor;
 Sweep.q0:=QuaternionFromMatrix3x3(AOrientation);
 Sweep.q:=Sweep.q0;
 SynchronizeProxies;
 SetToAwake;
end;

procedure TKraftRigidBody.SetOrientation(const x,y,z:TKraftScalar);
var Orientation:TKraftMatrix3x3;
begin
 Orientation:=Matrix3x3RotateZ(z);
 Matrix3x3Mul(Orientation,Matrix3x3RotateY(y));
 Matrix3x3Mul(Orientation,Matrix3x3RotateX(x));
 PKraftVector3(pointer(@WorldTransform[0,0]))^.xyz:=PKraftVector3(pointer(@Orientation[0,0]))^.xyz;
 PKraftVector3(pointer(@WorldTransform[1,0]))^.xyz:=PKraftVector3(pointer(@Orientation[1,0]))^.xyz;
 PKraftVector3(pointer(@WorldTransform[2,0]))^.xyz:=PKraftVector3(pointer(@Orientation[2,0]))^.xyz;
 UpdateWorldInertiaTensor;
 Sweep.q0:=QuaternionFromMatrix3x3(Orientation);
 Sweep.q:=Sweep.q0;
 SynchronizeProxies;
 SetToAwake;
end;

procedure TKraftRigidBody.AddOrientation(const x,y,z:TKraftScalar);
var Orientation:TKraftMatrix3x3;
begin
 Orientation:=Matrix3x3RotateZ(z);
 Matrix3x3Mul(Orientation,Matrix3x3RotateY(y));
 Matrix3x3Mul(Orientation,Matrix3x3RotateX(x));
 Orientation:=Matrix3x3TermMul(Orientation,QuaternionToMatrix3x3(Sweep.q));
 PKraftVector3(pointer(@WorldTransform[0,0]))^.xyz:=PKraftVector3(pointer(@Orientation[0,0]))^.xyz;
 PKraftVector3(pointer(@WorldTransform[1,0]))^.xyz:=PKraftVector3(pointer(@Orientation[1,0]))^.xyz;
 PKraftVector3(pointer(@WorldTransform[2,0]))^.xyz:=PKraftVector3(pointer(@Orientation[2,0]))^.xyz;
 UpdateWorldInertiaTensor;
 Sweep.q0:=QuaternionFromMatrix3x3(Orientation);
 Sweep.q:=Sweep.q0;
 SynchronizeProxies;
 SetToAwake;
end;

procedure TKraftRigidBody.LimitVelocities;
var Velocity:TKraftScalar;
begin
 if MaximalLinearVelocity>EPSILON then begin
  Velocity:=Vector3Length(LinearVelocity);
  if Velocity>MaximalLinearVelocity then begin
   Vector3Scale(LinearVelocity,MaximalLinearVelocity/Velocity);
  end;
 end;
 if MaximalAngularVelocity>EPSILON then begin
  Velocity:=Vector3Length(AngularVelocity);
  if Velocity>MaximalAngularVelocity then begin
   Vector3Scale(AngularVelocity,MaximalAngularVelocity/Velocity);
  end;
 end;
 if Physics.MaximalLinearVelocity>EPSILON then begin
  Velocity:=Vector3Length(LinearVelocity);
  if Velocity>Physics.MaximalLinearVelocity then begin
   Vector3Scale(LinearVelocity,Physics.MaximalLinearVelocity/Velocity);
  end;
 end;
 if Physics.MaximalAngularVelocity>EPSILON then begin
  Velocity:=Vector3Length(AngularVelocity);
  if Velocity>Physics.MaximalAngularVelocity then begin
   Vector3Scale(AngularVelocity,Physics.MaximalAngularVelocity/Velocity);
  end;
 end;
end;

procedure TKraftRigidBody.ApplyImpulseAtPosition(const Point,Impulse:TKraftVector3);
begin
 LinearVelocity:=Vector3Add(LinearVelocity,Vector3ScalarMul(Impulse,InverseMass));
 AngularVelocity:=Vector3Add(AngularVelocity,Vector3TermMatrixMul(Vector3Cross(Vector3Sub(Point,Sweep.c),Impulse),WorldInverseInertiaTensor));
end;

procedure TKraftRigidBody.ApplyImpulseAtRelativePosition(const RelativePosition,Impulse:TKraftVector3);
begin
 LinearVelocity:=Vector3Add(LinearVelocity,Vector3ScalarMul(Impulse,InverseMass));
 AngularVelocity:=Vector3Add(AngularVelocity,Vector3TermMatrixMul(Vector3Cross(RelativePosition,Impulse),WorldInverseInertiaTensor));
end;

procedure TKraftRigidBody.SetForceAtPosition(const AForce,APosition:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 SetWorldForce(AForce,AForceMode);
 SetWorldTorque(Vector3TermMatrixMul(Vector3Cross(Vector3Sub(aPosition,Sweep.c),AForce),WorldInverseInertiaTensor),AForceMode);
end;

procedure TKraftRigidBody.AddForceAtPosition(const AForce,APosition:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AddWorldForce(AForce,AForceMode);
 AddWorldTorque(Vector3TermMatrixMul(Vector3Cross(Vector3Sub(APosition,Sweep.c),AForce),WorldInverseInertiaTensor),AForceMode);
end;

procedure TKraftRigidBody.SetWorldForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 Force:=Vector3Origin;
 AddWorldForce(AForce,AForceMode);
end;

procedure TKraftRigidBody.AddWorldForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 case AForceMode of
  kfmForce:begin
   // The unit of the Force parameter is applied to the rigidbody as mass*distance/time^2.
   Force:=Vector3Add(Force,AForce);
  end;
  kfmAcceleration:begin
   // The unit of the Force parameter is applied to the rigidbody as distance/time^2.
   Force:=Vector3Add(Force,Vector3ScalarMul(AForce,Mass));
  end;
  kfmImpulse:begin
   // The unit of the Force parameter is applied to the rigidbody as mass*distance/time.
   Force:=Vector3Add(Force,Vector3ScalarMul(AForce,Physics.WorldInverseDeltaTime));
  end;
  kfmVelocity:begin
   // The unit of the Force parameter is applied to the rigidbody as distance/time.
   Force:=Vector3Add(Force,Vector3ScalarMul(AForce,Mass*Physics.WorldInverseDeltaTime));
  end;
 end;
end;

procedure TKraftRigidBody.SetBodyForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 SetWorldForce(Vector3TermMatrixMulBasis(AForce,WorldTransform),AForceMode);
end;

procedure TKraftRigidBody.AddBodyForce(const AForce:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AddWorldForce(Vector3TermMatrixMulBasis(AForce,WorldTransform),AForceMode);
end;

procedure TKraftRigidBody.SetWorldTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 Torque:=Vector3Origin;
 AddWorldTorque(ATorque,AForceMode);
end;

procedure TKraftRigidBody.AddWorldTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 case AForceMode of
  kfmForce:begin
   // The unit of the Torque parameter is applied to the rigidbody as mass*distance/time^2.
   Torque:=Vector3Add(Torque,ATorque);
  end;
  kfmAcceleration:begin
   // The unit of the Torque parameter is applied to the rigidbody as distance/time^2.
   Torque:=Vector3Add(Torque,Vector3ScalarMul(ATorque,Mass));
  end;
  kfmImpulse:begin
   // The unit of the Torque parameter is applied to the rigidbody as mass*distance/time.
   Torque:=Vector3Add(Torque,Vector3ScalarMul(ATorque,Physics.WorldInverseDeltaTime));
  end;
  kfmVelocity:begin
   // The unit of the Torque parameter is applied to the rigidbody as distance/time.
   Torque:=Vector3Add(Torque,Vector3ScalarMul(ATorque,Mass*Physics.WorldInverseDeltaTime));
  end;
 end;
end;

procedure TKraftRigidBody.SetBodyTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 SetWorldTorque(Vector3TermMatrixMulBasis(ATorque,WorldTransform),AForceMode);
end;

procedure TKraftRigidBody.AddBodyTorque(const ATorque:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AddWorldTorque(Vector3TermMatrixMulBasis(ATorque,WorldTransform),AForceMode);
end;

procedure TKraftRigidBody.SetWorldAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AngularVelocity:=Vector3Origin;
 AddWorldAngularVelocity(AAngularVelocity,AForceMode);
end;

procedure TKraftRigidBody.AddWorldAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 case AForceMode of
  kfmForce:begin
   // The unit of the Torque parameter is applied to the rigidbody as mass*distance/time^2.
   AngularVelocity:=Vector3Add(AngularVelocity,Vector3ScalarMul(AAngularVelocity,InverseMass*Physics.WorldDeltaTime));
  end;
  kfmAcceleration:begin
   // The unit of the Torque parameter is applied to the rigidbody as distance/time^2.
   AngularVelocity:=Vector3Add(AngularVelocity,Vector3ScalarMul(AAngularVelocity,Physics.WorldDeltaTime));
  end;
  kfmImpulse:begin
   // The unit of the Torque parameter is applied to the rigidbody as mass*distance/time.
   AngularVelocity:=Vector3Add(AngularVelocity,Vector3ScalarMul(AAngularVelocity,InverseMass));
  end;
  kfmVelocity:begin
   // The unit of the Torque parameter is applied to the rigidbody as distance/time.
   AngularVelocity:=Vector3Add(AngularVelocity,AAngularVelocity);
  end;
 end;
end;

procedure TKraftRigidBody.SetBodyAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 SetWorldAngularVelocity(Vector3TermMatrixMulBasis(AAngularVelocity,WorldTransform),AForceMode);
end;

procedure TKraftRigidBody.AddBodyAngularVelocity(const AAngularVelocity:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AddWorldAngularVelocity(Vector3TermMatrixMulBasis(AAngularVelocity,WorldTransform),AForceMode);
end;

procedure TKraftRigidBody.SetWorldAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 SetWorldAngularVelocity(Vector3TermMatrixMul(AAngularMomentum,WorldInverseInertiaTensor),AForceMode);
end;

procedure TKraftRigidBody.AddWorldAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AddWorldAngularVelocity(Vector3TermMatrixMul(AAngularMomentum,WorldInverseInertiaTensor),AForceMode);
end;

procedure TKraftRigidBody.SetBodyAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 SetBodyAngularVelocity(Vector3TermMatrixMul(AAngularMomentum,BodyInverseInertiaTensor),AForceMode);
end;

procedure TKraftRigidBody.AddBodyAngularMomentum(const AAngularMomentum:TKraftVector3;const AForceMode:TKraftForceMode=kfmForce);
begin
 AddBodyAngularVelocity(Vector3TermMatrixMul(AAngularMomentum,BodyInverseInertiaTensor),AForceMode);
end;

function TKraftRigidBody.GetAngularMomentum:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(AngularVelocity,WorldInertiaTensor);
end;

procedure TKraftRigidBody.SetAngularMomentum(const NewAngularMomentum:TKraftVector3);
begin
 AngularVelocity:=Vector3TermMatrixMul(NewAngularMomentum,WorldInverseInertiaTensor);
end;

constructor TKraftConstraint.Create(const APhysics:TKraft);
var RigidBodyIndex:longint;
    RigidBody:TKraftRigidBody;
    ConstraintEdge:PKraftConstraintEdge;
    ContactPairEdge:PKraftContactPairEdge;
    ContactPair:PKraftContactPair;
begin

 inherited Create;

 Physics:=APhysics;

 Parent:=nil;

 Children:=nil;
 CountChildren:=0;

 UserData:=nil;

 Flags:=(Flags-[kcfVisited])+[kcfActive];

 if assigned(Physics.ConstraintLast) then begin
  Physics.ConstraintLast.Next:=self;
  Previous:=Physics.ConstraintLast;
 end else begin
  Physics.ConstraintFirst:=self;
  Previous:=nil;
 end;
 Physics.ConstraintLast:=self;
 Next:=nil;

 for RigidBodyIndex:=0 to 1 do begin
  ConstraintEdge:=@ConstraintEdges[RigidBodyIndex];
  RigidBody:=RigidBodies[RigidBodyIndex];
  if assigned(RigidBody) then begin
   inc(RigidBody.CountConstraints);
   if assigned(RigidBody.ConstraintEdgeLast) then begin
    RigidBody.ConstraintEdgeLast.Next:=ConstraintEdge;
    ConstraintEdge^.Previous:=RigidBody.ConstraintEdgeLast;
   end else begin
    RigidBody.ConstraintEdgeFirst:=ConstraintEdge;
    ConstraintEdge^.Previous:=nil;
   end;
   RigidBody.ConstraintEdgeLast:=ConstraintEdge;
   ConstraintEdge^.Next:=nil;
   ConstraintEdge^.Constraint:=self;
   ConstraintEdge^.OtherRigidBody:=RigidBodies[(RigidBodyIndex+1) and 1];
  end else begin
   ConstraintEdge^.Previous:=nil;
   ConstraintEdge^.Next:=nil;
   ConstraintEdge^.Constraint:=nil;
   ConstraintEdge^.OtherRigidBody:=nil;
  end;
 end;

 // If the constraint prevents collisions, then flag any contacts for filtering.
 if not (kcfCollideConnected in Flags) then begin
  for RigidBodyIndex:=0 to 1 do begin
   ConstraintEdge:=@ConstraintEdges[RigidBodyIndex];
   RigidBody:=RigidBodies[RigidBodyIndex];
   if assigned(RigidBody) then begin
    ContactPairEdge:=RigidBody.ContactPairEdgeFirst;
    while assigned(ContactPairEdge) do begin
     ContactPair:=ContactPairEdge^.ContactPair;
     if assigned(ContactPair) then begin
      if ContactPairEdge^.OtherRigidBody=ConstraintEdge^.OtherRigidBody then begin
       // Flag the contact for filtering at the next time step (where either rigid body is awake).
       ContactPair^.Flags:=ContactPair^.Flags+[kcfFiltered];
       if assigned(ContactPair^.MeshContactPair) then begin
        ContactPair^.MeshContactPair.Flags:=ContactPair^.MeshContactPair.Flags+[kcfFiltered];
       end;
      end;
     end;
     ContactPairEdge:=ContactPairEdge^.Next;
    end;
   end;
  end;
 end;

 for RigidBodyIndex:=0 to 1 do begin
  RigidBody:=RigidBodies[RigidBodyIndex];
  if assigned(RigidBody) then begin
   RigidBody.SetToAwake;
  end;
 end;

 BreakThresholdForce:=MAX_SCALAR;

 BreakThresholdTorque:=MAX_SCALAR;

 OnBreak:=nil;

end;

destructor TKraftConstraint.Destroy;
var RigidBodyIndex,ConstraintIndex:longint;
    RigidBody:TKraftRigidBody;
    Constraint:TKraftConstraint;
    ConstraintEdge:PKraftConstraintEdge;
    ContactPairEdge:PKraftContactPairEdge;
    ContactPair:PKraftContactPair;
begin

 if assigned(Parent) then begin
  for ConstraintIndex:=0 to Parent.CountChildren-1 do begin
   if Parent.Children[ConstraintIndex]=self then begin
    Parent.Children[ConstraintIndex]:=nil;
   end;
  end;
 end;

 if CountChildren>0 then begin
  for ConstraintIndex:=0 to CountChildren-1 do begin
   Constraint:=Children[ConstraintIndex];
   if assigned(Constraint) then begin
    Children[ConstraintIndex]:=nil;
    Constraint.Free;
   end;
  end;
  SetLength(Children,0);
 end;

 if assigned(Previous) then begin
  Previous.Next:=Next;
 end else if Physics.ConstraintFirst=self then begin
  Physics.ConstraintFirst:=Next;
 end;
 if assigned(Next) then begin
  Next.Previous:=Previous;
 end else if Physics.ConstraintLast=self then begin
  Physics.ConstraintLast:=Previous;
 end;
 Previous:=nil;
 Next:=nil;

 for RigidBodyIndex:=0 to 1 do begin
  RigidBody:=RigidBodies[RigidBodyIndex];
  if assigned(RigidBody) then begin
   RigidBody.SetToAwake;
  end;
 end;

 for RigidBodyIndex:=0 to 1 do begin
  RigidBody:=RigidBodies[RigidBodyIndex];
  if assigned(RigidBody) then begin
   dec(RigidBody.CountConstraints);
   ConstraintEdge:=@ConstraintEdges[RigidBodyIndex];
   if assigned(ConstraintEdge^.Previous) then begin
    ConstraintEdge^.Previous.Next:=ConstraintEdge^.Next;
   end else if RigidBody.ConstraintEdgeFirst=ConstraintEdge then begin
    RigidBody.ConstraintEdgeFirst:=ConstraintEdge^.Next;
   end;
   if assigned(ConstraintEdge^.Next) then begin
    ConstraintEdge^.Next.Previous:=ConstraintEdge^.Previous;
   end else if RigidBody.ConstraintEdgeLast=ConstraintEdge then begin
    RigidBody.ConstraintEdgeLast:=ConstraintEdge^.Previous;
   end;
   ConstraintEdge^.Previous:=nil;
   ConstraintEdge^.Next:=nil;
  end;
 end;

 // If the constraint prevents collisions, then flag any contacts for filtering.
 if not (kcfCollideConnected in Flags) then begin
  for RigidBodyIndex:=0 to 1 do begin
   ConstraintEdge:=@ConstraintEdges[RigidBodyIndex];
   RigidBody:=RigidBodies[RigidBodyIndex];
   if assigned(RigidBody) then begin
    ContactPairEdge:=RigidBody.ContactPairEdgeFirst;
    while assigned(ContactPairEdge) do begin
     ContactPair:=ContactPairEdge^.ContactPair;
     if assigned(ContactPair) then begin
      if ContactPairEdge^.OtherRigidBody=ConstraintEdge^.OtherRigidBody then begin
       // Flag the contact for filtering at the next time step (where either rigid body is awake).
       ContactPair^.Flags:=ContactPair^.Flags+[kcfFiltered];
       if assigned(ContactPair^.MeshContactPair) then begin
        ContactPair^.MeshContactPair.Flags:=ContactPair^.MeshContactPair.Flags+[kcfFiltered];
       end;
      end;
     end;
     ContactPairEdge:=ContactPairEdge^.Next;
    end;
   end;
  end;
 end;

 inherited Destroy;
end;

procedure TKraftConstraint.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
begin
end;

procedure TKraftConstraint.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
begin
end;

function TKraftConstraint.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
begin
 result:=true;
end;

function TKraftConstraint.GetAnchorA:TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftConstraint.GetAnchorB:TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftConstraint.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftConstraint.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

constructor TKraftConstraintJointGrab.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const AWorldPoint:TKraftVector3;const AFrequencyHz:TKraftScalar=5.0;const ADampingRatio:TKraftScalar=0.7;const AMaximalForce:TKraftScalar=MAX_SCALAR;const ACollideConnected:boolean=false);
begin

 WorldPoint:=AWorldPoint;

 LocalAnchor:=Vector3TermMatrixMulInverted(AWorldPoint,ARigidBody.WorldTransform);

 FrequencyHz:=AFrequencyHz;
 DampingRatio:=ADampingRatio;
 AccumulatedImpulse:=Vector3Origin;
 Beta:=0.0;
 Gamma:=0.0;

 MaximalForce:=AMaximalForce;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBody;
 RigidBodies[1]:=nil;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointGrab.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointGrab.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA:PKraftVector3;
    qA:PKraftQuaternion;
    Omega,k,h,d:TKraftScalar;
    SkewSymmetricMatrix,MassMatrix:TKraftMatrix3x3;
begin

 IslandIndex:=RigidBodies[0].IslandIndices[Island.IslandIndex];

 LocalCenter:=RigidBodies[0].Sweep.LocalCenter;

 InverseMass:=RigidBodies[0].InverseMass;

 WorldInverseInertiaTensor:=RigidBodies[0].WorldInverseInertiaTensor;

 SolverVelocity:=@Island.Solver.Velocities[IslandIndex];

 SolverPosition:=@Island.Solver.Positions[IslandIndex];

 cA:=@SolverPosition^.Position;
 qA:=@SolverPosition^.Orientation;
 vA:=@SolverVelocity^.LinearVelocity;
 wA:=@SolverVelocity^.AngularVelocity;

 // Compute the effective mass matrix
 if InverseMass<>0.0 then begin
  Mass:=1.0/InverseMass;
 end else begin
  Mass:=0.0;
 end;

 // Frequency
 Omega:=pi2*FrequencyHz;

 // Damping coefficient
 d:=2.0*Mass*DampingRatio*Omega;

 // Spring stiffness
 k:=Mass*sqr(Omega);

 // Magic formulas
 h:=TimeStep.DeltaTime;
 Gamma:=h*(d+(h*k));
 if Gamma<>0.0 then begin
  Gamma:=1.0/Gamma;
 end else begin
  Gamma:=0.0;
 end;
 Beta:=h*k*Gamma;

 RelativePosition:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchor,LocalCenter),qA^);

{MassMatrix[0,0]:=(((sqr(RelativePosition.z)*WorldInverseInertiaTensor[1,1])-
                    ((RelativePosition.y*RelativePosition.z)*(WorldInverseInertiaTensor[1,2]+WorldInverseInertiaTensor[2,1])))+
                   (sqr(RelativePosition.y)*WorldInverseInertiaTensor[2,2]))+
                  (InverseMass+Gamma);
 MassMatrix[0,1]:=(((-(sqr(RelativePosition.z)*WorldInverseInertiaTensor[1,0]))+
                    ((RelativePosition.x*RelativePosition.z)*WorldInverseInertiaTensor[1,2]))+
                   ((RelativePosition.y*RelativePosition.z)*WorldInverseInertiaTensor[2,0]))-
                  ((RelativePosition.x*RelativePosition.y)*WorldInverseInertiaTensor[2,2]);
 MassMatrix[0,2]:=((((RelativePosition.y*RelativePosition.z)*WorldInverseInertiaTensor[1,0])- 
                    ((RelativePosition.x*RelativePosition.z)*WorldInverseInertiaTensor[1,1]))- 
                   (sqr(RelativePosition.y)*WorldInverseInertiaTensor[2,0]))+
                  ((RelativePosition.x*RelativePosition.y)*WorldInverseInertiaTensor[2,1]);
 MassMatrix[1,0]:=(((-(sqr(RelativePosition.z)*WorldInverseInertiaTensor[0,1]))+ 
                    ((RelativePosition.y*RelativePosition.z)*WorldInverseInertiaTensor[0,2]))+ 
                   ((RelativePosition.x*RelativePosition.z)*WorldInverseInertiaTensor[2,1]))- 
                  ((RelativePosition.x*RelativePosition.y)*WorldInverseInertiaTensor[2,2]);
 MassMatrix[1,1]:=(((sqr(RelativePosition.z)*WorldInverseInertiaTensor[0,0])-
                    ((RelativePosition.x*RelativePosition.z)*(WorldInverseInertiaTensor[0,2]+WorldInverseInertiaTensor[2,0])))+
                   (sqr(RelativePosition.x)*WorldInverseInertiaTensor[2,2]))+
                  (InverseMass+Gamma);
 MassMatrix[1,2]:=(((-((RelativePosition.y*RelativePosition.z)*WorldInverseInertiaTensor[0,0]))+
                    ((RelativePosition.x*RelativePosition.z)*WorldInverseInertiaTensor[0,1]))+
                   ((RelativePosition.x*RelativePosition.y)*WorldInverseInertiaTensor[2,0]))-
                  (sqr(RelativePosition.x)*WorldInverseInertiaTensor[2,1]);
 MassMatrix[2,0]:=((((RelativePosition.y*RelativePosition.z)*WorldInverseInertiaTensor[0,1])-
                    (sqr(RelativePosition.y)*WorldInverseInertiaTensor[0,2]))-
                   ((RelativePosition.x*RelativePosition.z)*WorldInverseInertiaTensor[1,1]))+
                  ((RelativePosition.x*RelativePosition.y)*WorldInverseInertiaTensor[1,2]);
 MassMatrix[2,1]:=(((-((RelativePosition.y*RelativePosition.z)*WorldInverseInertiaTensor[0,0]))+
                    ((RelativePosition.x*RelativePosition.y)*WorldInverseInertiaTensor[0,2])+
                   ((RelativePosition.x*RelativePosition.z)*WorldInverseInertiaTensor[1,0])))-
                  (sqr(RelativePosition.x)*WorldInverseInertiaTensor[1,2]);
 MassMatrix[2,2]:=(((sqr(RelativePosition.y)*WorldInverseInertiaTensor[0,0])-
                    ((RelativePosition.x*RelativePosition.y)*(WorldInverseInertiaTensor[0,1]+WorldInverseInertiaTensor[1,0])))+
                   (sqr(RelativePosition.x)*WorldInverseInertiaTensor[1,1]))+
                  (InverseMass+Gamma);
 Matrix3x3Inverse(EffectiveMass,MassMatrix);{}

 SkewSymmetricMatrix:=GetSkewSymmetricMatrixPlus(RelativePosition);

 MassMatrix[0,0]:=InverseMass+Gamma;
 MassMatrix[0,1]:=0.0;
 MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
 MassMatrix[0,3]:=0.0;
{$endif}
 MassMatrix[1,0]:=0.0;
 MassMatrix[1,1]:=MassMatrix[0,0];
 MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
 MassMatrix[1,3]:=0.0;
{$endif}
 MassMatrix[2,0]:=0.0;
 MassMatrix[2,1]:=0.0;
 MassMatrix[2,2]:=MassMatrix[0,0];
{$ifdef SIMD}
 MassMatrix[2,3]:=0.0;
{$endif}
 Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrix,WorldInverseInertiaTensor),SkewSymmetricMatrix));
 Matrix3x3Inverse(EffectiveMass,MassMatrix); (**)

 mC:=Vector3ScalarMul(Vector3Sub(Vector3Add(cA^,RelativePosition),WorldPoint),Beta);

 Vector3Scale(wA^,0.98);

 if Physics.WarmStarting then begin

  AccumulatedImpulse:=Vector3ScalarMul(AccumulatedImpulse,TimeStep.DeltaTimeRatio);

  Vector3DirectAdd(vA^,Vector3ScalarMul(AccumulatedImpulse,InverseMass));
  Vector3DirectAdd(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePosition,AccumulatedImpulse),WorldInverseInertiaTensor));

 end else begin

  AccumulatedImpulse:=Vector3Origin;

 end;

end;

procedure TKraftConstraintJointGrab.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA:PKraftVector3;
    Cdot,Impulse,OldImpulse:TKraftVector3;
    MaximalImpulse:TKraftScalar;
begin

 vA:=@SolverVelocity^.LinearVelocity;
 wA:=@SolverVelocity^.AngularVelocity;

 // Cdot = dot(u, v + cross(w, r))
 Cdot:=Vector3Add(vA^,Vector3Cross(wA^,RelativePosition));

 Impulse:=Vector3TermMatrixMul(Vector3Neg(Vector3Add(Cdot,Vector3Add(mC,Vector3ScalarMul(AccumulatedImpulse,Gamma)))),EffectiveMass);

 OldImpulse:=AccumulatedImpulse;
 Vector3DirectAdd(AccumulatedImpulse,Impulse);
 MaximalImpulse:=MaximalForce*TimeStep.DeltaTime;
 if Vector3Length(AccumulatedImpulse)>MaximalImpulse then begin
  Vector3Scale(AccumulatedImpulse,MaximalImpulse/Vector3Length(AccumulatedImpulse));
 end;
 Impulse:=Vector3Sub(AccumulatedImpulse,OldImpulse);

 Vector3DirectAdd(vA^,Vector3ScalarMul(Impulse,InverseMass));
 Vector3DirectAdd(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePosition,Impulse),WorldInverseInertiaTensor));

end;

function TKraftConstraintJointGrab.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
begin
 result:=true;
end;

function TKraftConstraintJointGrab.GetAnchor:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchor,RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointGrab.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(AccumulatedImpulse,InverseDeltaTime);
end;

function TKraftConstraintJointGrab.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftConstraintJointGrab.GetWorldPoint:TKraftVector3;
begin
 result:=WorldPoint;
end;

function TKraftConstraintJointGrab.GetMaximalForce:TKraftScalar;
begin
 result:=MaximalForce;
end;

procedure TKraftConstraintJointGrab.SetWorldPoint(AWorldPoint:TKraftVector3);
begin
 WorldPoint:=AWorldPoint;
end;

procedure TKraftConstraintJointGrab.SetMaximalForce(AMaximalForce:TKraftScalar);
begin
 MaximalForce:=AMaximalForce;
end;

constructor TKraftConstraintJointWorldPlaneDistance.Create(const APhysics:TKraft;const ARigidBody:TKraftRigidBody;const ALocalAnchorPoint:TKraftVector3;const AWorldPlane:TKraftPlane;const ADoubleSidedWorldPlane:boolean=true;const AWorldDistance:single=1.0;const ALimitBehavior:TKraftConstraintLimitBehavior=kclbLimitDistance;const AFrequencyHz:TKraftScalar=0.0;const ADampingRatio:TKraftScalar=0.0;const ACollideConnected:boolean=false);
begin

 LocalAnchor:=ALocalAnchorPoint;

 WorldPlane:=AWorldPlane;

 WorldPoint:=Vector3ScalarMul(AWorldPlane.Normal,-AWorldPlane.Distance);

 DoubleSidedWorldPlane:=ADoubleSidedWorldPlane;
 
 WorldDistance:=AWorldDistance;

// AnchorDistanceLength:=AWorldDistance;//Vector3Dist(WorldPoint,Vector3TermMatrixMul(ALocalAnchorPoint,ARigidBody.WorldTransform));

 LimitBehavior:=ALimitBehavior;

 FrequencyHz:=AFrequencyHz;
 DampingRatio:=ADampingRatio;
 AccumulatedImpulse:=0.0;
 Gamma:=0.0;
 Bias:=0.0;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBody;
 RigidBodies[1]:=nil;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointWorldPlaneDistance.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointWorldPlaneDistance.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA:PKraftVector3;
    qA:PKraftQuaternion;
    crAu,P,AbsolutePosition:TKraftVector3;
    l,TotalInverseMass,C,Omega,k,h,d:TKraftScalar;
begin

 IslandIndex:=RigidBodies[0].IslandIndices[Island.IslandIndex];

 LocalCenter:=RigidBodies[0].Sweep.LocalCenter;

 InverseMass:=RigidBodies[0].InverseMass;

 WorldInverseInertiaTensor:=RigidBodies[0].WorldInverseInertiaTensor;

 SolverVelocity:=@Island.Solver.Velocities[IslandIndex];

 SolverPosition:=@Island.Solver.Positions[IslandIndex];

 cA:=@SolverPosition^.Position;
 qA:=@SolverPosition^.Orientation;
 vA:=@SolverVelocity^.LinearVelocity;
 wA:=@SolverVelocity^.AngularVelocity;

 RelativePosition:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchor,LocalCenter),qA^);
 AbsolutePosition:=Vector3Add(cA^,RelativePosition);

 WorldPoint:=Vector3Add(AbsolutePosition,Vector3ScalarMul(WorldPlane.Normal,-PlaneVectorDistance(WorldPlane,AbsolutePosition)));
                         
 if DoubleSidedWorldPlane then begin

  mU:=Vector3Sub(WorldPoint,AbsolutePosition);

  // Handle singularity
  l:=Vector3Length(mU);
  if l>Physics.LinearSlop then begin
   Vector3Scale(mU,1.0/l);
  end else begin
   mU:=Vector3Origin;
  end;

 end else begin

  l:=PlaneVectorDistance(WorldPlane,AbsolutePosition);

  if abs(l)>Physics.LinearSlop then begin
   mU:=Vector3Neg(WorldPlane.Normal);
  end else begin
   mU:=Vector3Origin;
  end;

 end;

 SoftConstraint:=FrequencyHz>EPSILON;

 if SoftConstraint then begin

  // No limit state skipping for soft contraints
  Skip:=false;

 end else begin

  // Limit state skipping for non-soft contraints
  case LimitBehavior of
   kclbLimitMinimumDistance:begin
    Skip:=l>(WorldDistance+Physics.LinearSlop);
   end;
   kclbLimitMaximumDistance:begin
    Skip:=l<(WorldDistance-Physics.LinearSlop);
   end;
   else begin
    Skip:=false;
   end;
  end;

 end;

 if not Skip then begin

  crAu:=Vector3Cross(RelativePosition,mU);

  TotalInverseMass:=RigidBodies[0].InverseMass+
                    Vector3Dot(Vector3TermMatrixMul(crAu,WorldInverseInertiaTensor),crAu);

  // Compute the effective mass matrix
  if TotalInverseMass<>0.0 then begin
   Mass:=1.0/TotalInverseMass;
  end else begin
   Mass:=0.0;
  end;

  if SoftConstraint then begin

   C:=l-WorldDistance;

   // Frequency
   Omega:=pi2*FrequencyHz;

   // Damping coefficient
   d:=2.0*Mass*DampingRatio*Omega;

   // Spring stiffness
   k:=Mass*sqr(Omega);

   // Magic formulas
   h:=TimeStep.DeltaTime;
   Gamma:=h*(d+(h*k));
   if Gamma<>0.0 then begin
    Gamma:=1.0/Gamma;
   end else begin
    Gamma:=0.0;
   end;
   Bias:=C*h*k*Gamma;

   TotalInverseMass:=TotalInverseMass+Gamma;

   if TotalInverseMass<>0.0 then begin
    Mass:=1.0/TotalInverseMass;
   end else begin
    Mass:=0.0;
   end;

  end else begin

   Gamma:=0.0;
   Bias:=0.0;

  end;

 end;

 if Physics.WarmStarting and not Skip then begin

  AccumulatedImpulse:=AccumulatedImpulse*TimeStep.DeltaTimeRatio;

  P:=Vector3ScalarMul(mU,AccumulatedImpulse);

  Vector3DirectSub(vA^,Vector3ScalarMul(P,InverseMass));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePosition,P),WorldInverseInertiaTensor));

 end else begin

  AccumulatedImpulse:=0.0;

 end;


end;

procedure TKraftConstraintJointWorldPlaneDistance.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA:PKraftVector3;
    vpA,P:TKraftVector3;
    Cdot,Impulse,OldImpulse:TKraftScalar;
begin

 if not Skip then begin

  vA:=@SolverVelocity^.LinearVelocity;
  wA:=@SolverVelocity^.AngularVelocity;

  // Cdot = dot(u, v + cross(w, r))
  vpA:=Vector3Add(vA^,Vector3Cross(wA^,RelativePosition));
  Cdot:=Vector3Dot(mU,Vector3Neg(vpA));

  Impulse:=-(Mass*((Cdot+Bias)+(Gamma*AccumulatedImpulse)));

  if SoftConstraint then begin
   case LimitBehavior of
    kclbLimitMinimumDistance:begin
     OldImpulse:=AccumulatedImpulse;
     AccumulatedImpulse:=Max(0.0,AccumulatedImpulse+Impulse);
     Impulse:=AccumulatedImpulse-OldImpulse;
    end;
    kclbLimitMaximumDistance:begin
     OldImpulse:=AccumulatedImpulse;
     AccumulatedImpulse:=Min(0.0,AccumulatedImpulse+Impulse);
     Impulse:=AccumulatedImpulse-OldImpulse;
    end;
    else begin
     AccumulatedImpulse:=AccumulatedImpulse+Impulse;
    end;
   end;
  end else begin
   AccumulatedImpulse:=AccumulatedImpulse+Impulse;
  end;
  
  P:=Vector3ScalarMul(mU,Impulse);

  Vector3DirectSub(vA^,Vector3ScalarMul(P,InverseMass));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePosition,P),WorldInverseInertiaTensor));

 end;

end;

function TKraftConstraintJointWorldPlaneDistance.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA:PKraftVector3;
    qA:PKraftQuaternion;
    rA,AbsolutePosition,u,P:TKraftVector3;
    l,C,Impulse:TKraftScalar;
begin
 if SoftConstraint or Skip then begin

  // There is no position correction for soft distance constraints or invalid limit states
  result:=true;

 end else begin

  cA:=@SolverPosition^.Position;
  qA:=@SolverPosition^.Orientation;

  rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchor,LocalCenter),qA^);

  AbsolutePosition:=Vector3Add(cA^,RelativePosition);

  if DoubleSidedWorldPlane then begin

   WorldPoint:=Vector3Add(AbsolutePosition,Vector3ScalarMul(WorldPlane.Normal,-PlaneVectorDistance(WorldPlane,AbsolutePosition)));

   u:=Vector3Sub(WorldPoint,AbsolutePosition);

   l:=Vector3LengthNormalize(u);

   C:=Min(Max(l-WorldDistance,-Physics.MaximalLinearCorrection),Physics.MaximalLinearCorrection);

   Impulse:=-(Mass*C);

   P:=Vector3ScalarMul(u,Impulse);

  end else begin

   C:=Min(Max(WorldDistance-PlaneVectorDistance(WorldPlane,AbsolutePosition),-Physics.MaximalLinearCorrection),Physics.MaximalLinearCorrection);

   Impulse:=-(Mass*C);

   P:=Vector3ScalarMul(WorldPlane.Normal,Impulse);

  end;

  Vector3DirectSub(cA^,Vector3ScalarMul(P,InverseMass));
  QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(P)),WorldInverseInertiaTensor),1.0);

  result:=abs(C)<Physics.LinearSlop;

 end;
end;

function TKraftConstraintJointWorldPlaneDistance.GetAnchor:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchor,RigidBodies[0].WorldTransform);
end;
                                         
function TKraftConstraintJointWorldPlaneDistance.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(mU,AccumulatedImpulse*InverseDeltaTime);
end;

function TKraftConstraintJointWorldPlaneDistance.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftConstraintJointWorldPlaneDistance.GetWorldPoint:TKraftVector3;
begin
 result:=WorldPoint;
end;

function TKraftConstraintJointWorldPlaneDistance.GetWorldPlane:TKraftPlane;
begin
 result:=WorldPlane;
end;

procedure TKraftConstraintJointWorldPlaneDistance.SetWorldPlane(const AWorldPlane:TKraftPlane);
begin
 WorldPlane:=AWorldPlane;
end;

function TKraftConstraintJointWorldPlaneDistance.GetWorldDistance:TKraftScalar;
begin
 result:=WorldDistance;
end;

procedure TKraftConstraintJointWorldPlaneDistance.SetWorldDistance(const AWorldDistance:TKraftScalar);
begin
 WorldDistance:=AWorldDistance;
end;

constructor TKraftConstraintJointDistance.Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const ALocalAnchorPointA,ALocalAnchorPointB:TKraftVector3;const AFrequencyHz:TKraftScalar=0.0;const ADampingRatio:TKraftScalar=0.0;const ACollideConnected:boolean=false);
begin

 LocalAnchors[0]:=ALocalAnchorPointA;
 LocalAnchors[1]:=ALocalAnchorPointB;

 AnchorDistanceLength:=Vector3Dist(Vector3TermMatrixMul(ALocalAnchorPointB,ARigidBodyB.WorldTransform),Vector3TermMatrixMul(ALocalAnchorPointA,ARigidBodyA.WorldTransform));
 FrequencyHz:=AFrequencyHz;
 DampingRatio:=ADampingRatio;
 AccumulatedImpulse:=0.0;
 Gamma:=0.0;
 Bias:=0.0;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointDistance.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointDistance.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    crAu,crBu,P:TKraftVector3;
    l,InverseMass,C,Omega,k,h,d:TKraftScalar;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);
 mU:=Vector3Sub(Vector3Add(cB^,RelativePositions[1]),Vector3Add(cA^,RelativePositions[0]));

 // Handle singularity
 l:=Vector3Length(mU);
 if l>Physics.LinearSlop then begin
  Vector3Scale(mU,1.0/l);
 end else begin
  mU:=Vector3Origin;
 end;

 crAu:=Vector3Cross(RelativePositions[0],mU);
 crBu:=Vector3Cross(RelativePositions[1],mU);

 InverseMass:=RigidBodies[0].InverseMass+
              RigidBodies[1].InverseMass+
              Vector3Dot(Vector3TermMatrixMul(crAu,WorldInverseInertiaTensors[0]),crAu)+
              Vector3Dot(Vector3TermMatrixMul(crBu,WorldInverseInertiaTensors[1]),crBu);

 // Compute the effective mass matrix
 if InverseMass<>0.0 then begin
  Mass:=1.0/InverseMass;
 end else begin
  Mass:=0.0;
 end;

 if FrequencyHz>EPSILON then begin

  C:=l-AnchorDistanceLength;

  // Frequency
  Omega:=pi2*FrequencyHz;

  // Damping coefficient
  d:=2.0*Mass*DampingRatio*Omega;

  // Spring stiffness
	k:=Mass*sqr(Omega);

  // Magic formulas
  h:=TimeStep.DeltaTime;
  Gamma:=h*(d+(h*k));
  if Gamma<>0.0 then begin
   Gamma:=1.0/Gamma;
  end else begin
   Gamma:=0.0;
  end;
	Bias:=C*h*k*Gamma;

  InverseMass:=InverseMass+Gamma;

  if InverseMass<>0.0 then begin
   Mass:=1.0/InverseMass;
  end else begin
   Mass:=0.0;
  end;

 end else begin

  Gamma:=0.0;
  Bias:=0.0;

 end;

 if Physics.WarmStarting then begin

  AccumulatedImpulse:=AccumulatedImpulse*TimeStep.DeltaTimeRatio;

  P:=Vector3ScalarMul(mU,AccumulatedImpulse);

  Vector3DirectSub(vA^,Vector3ScalarMul(P,InverseMasses[0]));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],P),WorldInverseInertiaTensors[0]));

  Vector3DirectAdd(vB^,Vector3ScalarMul(P,InverseMasses[1]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],P),WorldInverseInertiaTensors[1]));

 end else begin

  AccumulatedImpulse:=0.0;

 end;

end;

procedure TKraftConstraintJointDistance.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    vpA,vpB,P:TKraftVector3;
    Cdot,Impulse:TKraftScalar;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 // Cdot = dot(u, v + cross(w, r))
 vpA:=Vector3Add(vA^,Vector3Cross(wA^,RelativePositions[0]));
 vpB:=Vector3Add(vB^,Vector3Cross(wB^,RelativePositions[1]));
 Cdot:=Vector3Dot(mU,Vector3Sub(vpB,vpA));

 Impulse:=-(Mass*((Cdot+Bias)+(Gamma*AccumulatedImpulse)));
 AccumulatedImpulse:=AccumulatedImpulse+Impulse;

 P:=Vector3ScalarMul(mU,Impulse);

 Vector3DirectSub(vA^,Vector3ScalarMul(P,InverseMasses[0]));
 Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],P),WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(P,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],P),WorldInverseInertiaTensors[1]));

end;

function TKraftConstraintJointDistance.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,u,P:TKraftVector3;
    l,C,Impulse:TKraftScalar;
begin
 if FrequencyHz>EPSILON then begin

  // There is no position correction for soft distance constraints
  result:=true;

 end else begin

  cA:=@SolverPositions[0]^.Position;
  qA:=@SolverPositions[0]^.Orientation;

  cB:=@SolverPositions[1]^.Position;
  qB:=@SolverPositions[1]^.Orientation;

  rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
  rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);
  u:=Vector3Sub(Vector3Add(cB^,rB),Vector3Add(cA^,rA));

  l:=Vector3LengthNormalize(u);
  C:=Min(Max(l-AnchorDistanceLength,-Physics.MaximalLinearCorrection),Physics.MaximalLinearCorrection);

  Impulse:=-(Mass*C);

  P:=Vector3ScalarMul(u,Impulse);

  Vector3DirectSub(cA^,Vector3ScalarMul(P,InverseMasses[0]));
  QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(P)),WorldInverseInertiaTensors[0]),1.0);

  Vector3DirectAdd(cB^,Vector3ScalarMul(P,InverseMasses[1]));
  QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Vector3Cross(rB,P),WorldInverseInertiaTensors[1]),1.0);

  result:=abs(C)<Physics.LinearSlop;

 end;
end;

function TKraftConstraintJointDistance.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointDistance.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointDistance.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(mU,AccumulatedImpulse*InverseDeltaTime);
end;

function TKraftConstraintJointDistance.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

constructor TKraftConstraintJointRope.Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const ALocalAnchorPointA,ALocalAnchorPointB:TKraftVector3;const AMaximalLength:TKraftScalar=1.0;const ACollideConnected:boolean=false);
begin

 LocalAnchors[0]:=ALocalAnchorPointA;
 LocalAnchors[1]:=ALocalAnchorPointB;

 MaximalLength:=AMaximalLength;

 AccumulatedImpulse:=0.0;

 LimitState:=kclsInactiveLimit;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointRope.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointRope.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    crAu,crBu,P:TKraftVector3;
    InverseMass,C:TKraftScalar;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);
 mU:=Vector3Sub(Vector3Add(cB^,RelativePositions[1]),Vector3Add(cA^,RelativePositions[0]));

 CurrentLength:=Vector3Length(mU);

 C:=CurrentLength-MaximalLength;
 if C>0.0 then begin
  LimitState:=kclsAtUpperLimit;
 end else begin
  LimitState:=kclsInactiveLimit;
 end;

 // Handle singularity
 if CurrentLength>Physics.LinearSlop then begin

  Vector3Scale(mU,1.0/CurrentLength);

  crAu:=Vector3Cross(RelativePositions[0],mU);
  crBu:=Vector3Cross(RelativePositions[1],mU);

  InverseMass:=RigidBodies[0].InverseMass+
               RigidBodies[1].InverseMass+
               Vector3Dot(Vector3TermMatrixMul(crAu,WorldInverseInertiaTensors[0]),crAu)+
               Vector3Dot(Vector3TermMatrixMul(crBu,WorldInverseInertiaTensors[1]),crBu);

  // Compute the effective mass matrix
  if InverseMass<>0.0 then begin
   Mass:=1.0/InverseMass;
  end else begin
   Mass:=0.0;
  end;

  if Physics.WarmStarting then begin

   AccumulatedImpulse:=AccumulatedImpulse*TimeStep.DeltaTimeRatio;

   P:=Vector3ScalarMul(mU,AccumulatedImpulse);

   Vector3DirectSub(vA^,Vector3ScalarMul(P,InverseMasses[0]));
   Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],P),WorldInverseInertiaTensors[0]));

   Vector3DirectAdd(vB^,Vector3ScalarMul(P,InverseMasses[1]));
   Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],P),WorldInverseInertiaTensors[1]));

  end else begin

   AccumulatedImpulse:=0.0;

  end;
 
 end else begin

  mU:=Vector3Origin;
  Mass:=0.0;
  AccumulatedImpulse:=0.0;
  
 end;

end;

procedure TKraftConstraintJointRope.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    vpA,vpB,P:TKraftVector3;
    C,Cdot,Impulse,OldImpulse:TKraftScalar;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 // Cdot = dot(u, v + cross(w, r))
 vpA:=Vector3Add(vA^,Vector3Cross(wA^,RelativePositions[0]));
 vpB:=Vector3Add(vB^,Vector3Cross(wB^,RelativePositions[1]));
 C:=CurrentLength-MaximalLength;
 Cdot:=Vector3Dot(mU,Vector3Sub(vpB,vpA));

 // Predictive constraint
 if C<0.0 then begin
  Cdot:=Cdot+(C*TimeStep.InverseDeltaTime);
 end;

 Impulse:=-(Mass*Cdot);
 OldImpulse:=AccumulatedImpulse;
 AccumulatedImpulse:=Min(0.0,AccumulatedImpulse+Impulse);
 Impulse:=AccumulatedImpulse-OldImpulse;

 P:=Vector3ScalarMul(mU,Impulse);

 Vector3DirectSub(vA^,Vector3ScalarMul(P,InverseMasses[0]));
 Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],P),WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(P,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],P),WorldInverseInertiaTensors[1]));

end;

function TKraftConstraintJointRope.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,u,P:TKraftVector3;
    Len,C,Impulse:TKraftScalar;
begin

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;

 rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);
 u:=Vector3Sub(Vector3Add(cB^,rB),Vector3Add(cA^,rA));

 Len:=Vector3LengthNormalize(u);
 C:=Min(Max(Len-MaximalLength,0.0),Physics.MaximalLinearCorrection);

 Impulse:=-(Mass*C);

 P:=Vector3ScalarMul(u,Impulse);

 Vector3DirectSub(cA^,Vector3ScalarMul(P,InverseMasses[0]));
 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(P)),WorldInverseInertiaTensors[0]),1.0);

 Vector3DirectAdd(cB^,Vector3ScalarMul(P,InverseMasses[1]));
 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Vector3Cross(rB,P),WorldInverseInertiaTensors[1]),1.0);

 result:=(Len-MaximalLength)<Physics.LinearSlop;

end;

function TKraftConstraintJointRope.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointRope.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointRope.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(mU,AccumulatedImpulse*InverseDeltaTime);
end;

function TKraftConstraintJointRope.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

constructor TKraftConstraintJointPulley.Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AWorldGroundAnchorA,AWorldGroundAnchorB,AWorldAnchorPointA,AWorldAnchorPointB:TKraftVector3;const ARatio:TKraftScalar=1.0;const ACollideConnected:boolean=false);
begin

 GroundAnchors[0]:=AWorldGroundAnchorA;
 GroundAnchors[1]:=AWorldGroundAnchorB;

 LocalAnchors[0]:=Vector3TermMatrixMulInverted(AWorldAnchorPointA,ARigidBodyA.WorldTransform);
 LocalAnchors[1]:=Vector3TermMatrixMulInverted(AWorldAnchorPointB,ARigidBodyB.WorldTransform);

 Lengths[0]:=Vector3Dist(AWorldAnchorPointA,AWorldGroundAnchorA);
 Lengths[1]:=Vector3Dist(AWorldAnchorPointB,AWorldGroundAnchorB);

 Ratio:=ARatio;

 Constant:=Lengths[0]+(Lengths[1]*Ratio);
        
 AccumulatedImpulse:=0.0;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointPulley.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointPulley.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    ruA,ruB,PA,PB:TKraftVector3;
    LengthA,LengthB,mA,mB,InverseMass:TKraftScalar;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 mU[0]:=Vector3Add(cA^,RelativePositions[0]);
 mU[1]:=Vector3Add(cB^,RelativePositions[1]);

 LengthA:=Vector3Length(mU[0]);
 LengthB:=Vector3Length(mU[1]);

 if LengthA>(10.0*Physics.LinearSlop) then begin
  Vector3Scale(mU[0],1.0/LengthA);
 end else begin
  mU[0]:=Vector3Origin;
 end;

 if LengthB>(10.0*Physics.LinearSlop) then begin
  Vector3Scale(mU[1],1.0/LengthB);
 end else begin
  mU[1]:=Vector3Origin;
 end;

 ruA:=Vector3Cross(RelativePositions[0],mU[0]);
 ruB:=Vector3Cross(RelativePositions[1],mU[1]);

 mA:=RigidBodies[0].InverseMass+Vector3Dot(Vector3TermMatrixMul(ruA,WorldInverseInertiaTensors[0]),ruA);
 mB:=RigidBodies[1].InverseMass+Vector3Dot(Vector3TermMatrixMul(ruB,WorldInverseInertiaTensors[1]),ruB);

 InverseMass:=mA+(mB*sqr(Ratio));

 // Compute the effective mass matrix
 if InverseMass<>0.0 then begin
  Mass:=1.0/InverseMass;
 end else begin
  Mass:=0.0;
 end;

 if Physics.WarmStarting then begin

  AccumulatedImpulse:=AccumulatedImpulse*TimeStep.DeltaTimeRatio;

  PA:=Vector3ScalarMul(mU[0],-AccumulatedImpulse);
  PB:=Vector3ScalarMul(mU[1],-(AccumulatedImpulse*Ratio));

  Vector3DirectAdd(vA^,Vector3ScalarMul(PA,InverseMasses[0]));
  Vector3DirectAdd(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],PA),WorldInverseInertiaTensors[0]));

  Vector3DirectAdd(vB^,Vector3ScalarMul(PB,InverseMasses[1]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],PB),WorldInverseInertiaTensors[1]));

 end else begin

  AccumulatedImpulse:=0.0;

 end;

end;

procedure TKraftConstraintJointPulley.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    vpA,vpB,PA,PB:TKraftVector3;
    Cdot,Impulse:TKraftScalar;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 vpA:=Vector3Add(vA^,Vector3Cross(wA^,RelativePositions[0]));
 vpB:=Vector3Add(vB^,Vector3Cross(wB^,RelativePositions[1]));

 Cdot:=(-(Vector3Dot(mU[0],vpA)))-(Vector3Dot(mU[1],vpB)*Ratio);
 Impulse:=-(Mass*Cdot);
 AccumulatedImpulse:=AccumulatedImpulse+Impulse;

 PA:=Vector3ScalarMul(mU[0],-Impulse);
 PB:=Vector3ScalarMul(mU[1],-(Impulse*Ratio));

 Vector3DirectAdd(vA^,Vector3ScalarMul(PA,InverseMasses[0]));
 Vector3DirectAdd(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],PA),WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(PB,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],PB),WorldInverseInertiaTensors[1]));

end;

function TKraftConstraintJointPulley.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,uA,uB,ruA,ruB,PA,PB:TKraftVector3;
    LengthA,LengthB,mA,mB,InverseMass,Mass,C,LinearError,Impulse:TKraftScalar;
begin

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;

 rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 // Get the pulley axes
 uA:=Vector3Add(cA^,rA);
 uB:=Vector3Add(cB^,rB);

 LengthA:=Vector3Length(uA);
 LengthB:=Vector3Length(uB);

 if LengthA>(10.0*Physics.LinearSlop) then begin
  Vector3Scale(uA,1.0/LengthA);
 end else begin
  uA:=Vector3Origin;
 end;

 if LengthB>(10.0*Physics.LinearSlop) then begin
  Vector3Scale(uB,1.0/LengthB);
 end else begin
  uB:=Vector3Origin;
 end;

 ruA:=Vector3Cross(RelativePositions[0],mU[0]);
 ruB:=Vector3Cross(RelativePositions[1],mU[1]);

 mA:=RigidBodies[0].InverseMass+Vector3Dot(Vector3TermMatrixMul(ruA,WorldInverseInertiaTensors[0]),ruA);
 mB:=RigidBodies[1].InverseMass+Vector3Dot(Vector3TermMatrixMul(ruB,WorldInverseInertiaTensors[1]),ruB);

 InverseMass:=mA+(mB*sqr(Ratio));

 // Compute the effective mass matrix
 if InverseMass<>0.0 then begin
  Mass:=1.0/InverseMass;
 end else begin
  Mass:=0.0;
 end;

 C:=Constant-(LengthA+(LengthB*Ratio));

 LinearError:=abs(c);

 Impulse:=-(Mass*C);

 PA:=Vector3ScalarMul(uA,-Impulse);
 PB:=Vector3ScalarMul(uB,-(Impulse*Ratio));

 Vector3DirectAdd(cA^,Vector3ScalarMul(PA,InverseMasses[0]));
 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,PA),WorldInverseInertiaTensors[0]),1.0);

 Vector3DirectAdd(cB^,Vector3ScalarMul(PB,InverseMasses[1]));
 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Vector3Cross(rB,PB),WorldInverseInertiaTensors[1]),1.0);

 result:=LinearError<Physics.LinearSlop;

end;

function TKraftConstraintJointPulley.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointPulley.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointPulley.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(mU[1],AccumulatedImpulse*InverseDeltaTime);
end;

function TKraftConstraintJointPulley.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

function TKraftConstraintJointPulley.GetCurrentLengthA:TKraftScalar;
begin
 result:=Vector3Dist(Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform),GroundAnchors[0]);
end;

function TKraftConstraintJointPulley.GetCurrentLengthB:TKraftScalar;
begin
 result:=Vector3Dist(Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform),GroundAnchors[1]);
end;

constructor TKraftConstraintJointBallSocket.Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AWorldAnchorPoint:TKraftVector3;const ACollideConnected:boolean=false);
begin

 LocalAnchors[0]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyA.WorldTransform);
 LocalAnchors[1]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyB.WorldTransform);

 AccumulatedImpulse:=Vector3Origin;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

constructor TKraftConstraintJointBallSocket.Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const ALocalAnchorPointA,ALocalAnchorPointB:TKraftVector3;const ACollideConnected:boolean=false);
begin

 LocalAnchors[0]:=ALocalAnchorPointA;
 LocalAnchors[1]:=ALocalAnchorPointB;

 AccumulatedImpulse:=Vector3Origin;

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;


destructor TKraftConstraintJointBallSocket.Destroy;
begin
 inherited Destroy;
end;
                                                   
procedure TKraftConstraintJointBallSocket.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    InverseMassOfBodies:TKraftScalar;
    SkewSymmetricMatrices:array[0..1] of TKraftMatrix3x3;
    MassMatrix:TKraftMatrix3x3;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 SkewSymmetricMatrices[0]:=GetSkewSymmetricMatrixPlus(RelativePositions[0]);
 SkewSymmetricMatrices[1]:=GetSkewSymmetricMatrixPlus(RelativePositions[1]);

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  MassMatrix[0,0]:=InverseMassOfBodies;
  MassMatrix[0,1]:=0.0;
  MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[0,3]:=0.0;
{$endif}
  MassMatrix[1,0]:=0.0;
  MassMatrix[1,1]:=InverseMassOfBodies;
  MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[1,3]:=0.0;
{$endif}
  MassMatrix[2,0]:=0.0;
  MassMatrix[2,1]:=0.0;
  MassMatrix[2,2]:=InverseMassOfBodies;
{$ifdef SIMD}
  MassMatrix[2,3]:=0.0;
{$endif}
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[0],WorldInverseInertiaTensors[0]),SkewSymmetricMatrices[0]));
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[1],WorldInverseInertiaTensors[1]),SkewSymmetricMatrices[1]));
  InverseMassMatrix:=Matrix3x3TermInverse(MassMatrix);
 end else begin
  InverseMassMatrix:=Matrix3x3Null;
 end;

 if Physics.WarmStarting then begin

  AccumulatedImpulse:=Vector3ScalarMul(AccumulatedImpulse,TimeStep.DeltaTimeRatio);

// writeln('BallWarm ',Vector3Length(AccumulatedImpulse):1:8);

  Vector3DirectSub(vA^,Vector3ScalarMul(AccumulatedImpulse,InverseMasses[0]));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],AccumulatedImpulse),WorldInverseInertiaTensors[0]));

  Vector3DirectAdd(vB^,Vector3ScalarMul(AccumulatedImpulse,InverseMasses[1]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],AccumulatedImpulse),WorldInverseInertiaTensors[1]));

 end else begin

  AccumulatedImpulse:=Vector3Origin;

 end;

end;

procedure TKraftConstraintJointBallSocket.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    vpA,vpB,Jv,Impulse:TKraftVector3;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 // Cdot = dot(u, v + cross(w, r))
 vpA:=Vector3Add(vA^,Vector3Cross(wA^,RelativePositions[0]));
 vpB:=Vector3Add(vB^,Vector3Cross(wB^,RelativePositions[1]));
 Jv:=Vector3Sub(vpB,vpA);

 Impulse:=Vector3TermMatrixMul(Vector3Neg(Jv),InverseMassMatrix);

 AccumulatedImpulse:=Vector3Add(AccumulatedImpulse,Impulse);

// writeln('BallVelo ',Vector3Length(Impulse):1:8);

 Vector3DirectSub(vA^,Vector3ScalarMul(Impulse,InverseMasses[0]));
 Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],Impulse),WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(Impulse,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],Impulse),WorldInverseInertiaTensors[1]));

end;

function TKraftConstraintJointBallSocket.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,TranslationError,Impulse:TKraftVector3;
    InverseMassOfBodies:TKraftScalar;
    SkewSymmetricMatrices:array[0..1] of TKraftMatrix3x3;
    MassMatrix:TKraftMatrix3x3;
begin

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;

 rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 SkewSymmetricMatrices[0]:=GetSkewSymmetricMatrixPlus(rA);
 SkewSymmetricMatrices[1]:=GetSkewSymmetricMatrixPlus(rB);

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  MassMatrix[0,0]:=InverseMassOfBodies;
  MassMatrix[0,1]:=0.0;
  MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[0,3]:=0.0;
{$endif}
  MassMatrix[1,0]:=0.0;
  MassMatrix[1,1]:=InverseMassOfBodies;
  MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[1,3]:=0.0;
{$endif}
  MassMatrix[2,0]:=0.0;
  MassMatrix[2,1]:=0.0;
  MassMatrix[2,2]:=InverseMassOfBodies;
{$ifdef SIMD}
  MassMatrix[2,3]:=0.0;
{$endif}
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[0],WorldInverseInertiaTensors[0]),SkewSymmetricMatrices[0]));
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[1],WorldInverseInertiaTensors[1]),SkewSymmetricMatrices[1]));
  InverseMassMatrix:=Matrix3x3TermInverse(MassMatrix);
 end else begin
  InverseMassMatrix:=Matrix3x3Null;
 end;

 TranslationError:=Vector3Sub(Vector3Add(cB^,rB),Vector3Add(cA^,rA));

 Impulse:=Vector3TermMatrixMul(Vector3Neg(TranslationError),InverseMassMatrix);

// writeln('BallPos ',Vector3Length(AccumulatedImpulse):1:8,' ',TranslationError.x:1:8,' ',TranslationError.y:1:8,' ',TranslationError.z:1:8);

 Vector3DirectSub(cA^,Vector3ScalarMul(Impulse,InverseMasses[0]));
 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(Impulse)),WorldInverseInertiaTensors[0]),1.0);

 Vector3DirectAdd(cB^,Vector3ScalarMul(Impulse,InverseMasses[1]));
 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Vector3Cross(rB,Impulse),WorldInverseInertiaTensors[1]),1.0);

 result:=Vector3Length(TranslationError)<Physics.LinearSlop;

end;

function TKraftConstraintJointBallSocket.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointBallSocket.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointBallSocket.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(AccumulatedImpulse,InverseDeltaTime);
end;

function TKraftConstraintJointBallSocket.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3Origin;
end;

constructor TKraftConstraintJointFixed.Create(const APhysics:TKraft;const ARigidBodyA,ARigidBodyB:TKraftRigidBody;const AWorldAnchorPoint:TKraftVector3;const ACollideConnected:boolean=false);
begin

 LocalAnchors[0]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyA.WorldTransform);
 LocalAnchors[1]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyB.WorldTransform);

 AccumulatedImpulseTranslation:=Vector3Origin;
 AccumulatedImpulseRotation:=Vector3Origin;

 InverseInitialOrientationDifference:=QuaternionInverse(QuaternionTermNormalize(QuaternionMul(ARigidBodyB.Sweep.q0,QuaternionInverse(ARigidBodyA.Sweep.q0))));

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointFixed.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointFixed.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    InverseMassOfBodies:TKraftScalar;
    SkewSymmetricMatrices:array[0..1] of TKraftMatrix3x3;
    MassMatrix:TKraftMatrix3x3;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 SkewSymmetricMatrices[0]:=GetSkewSymmetricMatrixPlus(RelativePositions[0]);
 SkewSymmetricMatrices[1]:=GetSkewSymmetricMatrixPlus(RelativePositions[1]);

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  MassMatrix[0,0]:=InverseMassOfBodies;
  MassMatrix[0,1]:=0.0;
  MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[0,3]:=0.0;
{$endif}
  MassMatrix[1,0]:=0.0;
  MassMatrix[1,1]:=InverseMassOfBodies;
  MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[1,3]:=0.0;
{$endif}
  MassMatrix[2,0]:=0.0;
  MassMatrix[2,1]:=0.0;
  MassMatrix[2,2]:=InverseMassOfBodies;
{$ifdef SIMD}
  MassMatrix[2,3]:=0.0;
{$endif}
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[0],WorldInverseInertiaTensors[0]),SkewSymmetricMatrices[0]));
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[1],WorldInverseInertiaTensors[1]),SkewSymmetricMatrices[1]));
  InverseMassMatrixTranslation:=Matrix3x3TermInverse(MassMatrix);
  InverseMassMatrixRotation:=Matrix3x3TermInverse(Matrix3x3TermAdd(WorldInverseInertiaTensors[0],WorldInverseInertiaTensors[1]));
 end else begin
  InverseMassMatrixTranslation:=Matrix3x3Null;
  InverseMassMatrixRotation:=Matrix3x3Null;
 end;

 if Physics.WarmStarting then begin

  AccumulatedImpulseTranslation:=Vector3ScalarMul(AccumulatedImpulseTranslation,TimeStep.DeltaTimeRatio);
  AccumulatedImpulseRotation:=Vector3ScalarMul(AccumulatedImpulseRotation,TimeStep.DeltaTimeRatio);

  Vector3DirectSub(vA^,Vector3ScalarMul(AccumulatedImpulseTranslation,InverseMasses[0]));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Add(Vector3Cross(RelativePositions[0],AccumulatedImpulseTranslation),AccumulatedImpulseRotation),WorldInverseInertiaTensors[0]));

  Vector3DirectAdd(vB^,Vector3ScalarMul(AccumulatedImpulseTranslation,InverseMasses[1]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Add(Vector3Cross(RelativePositions[1],AccumulatedImpulseTranslation),AccumulatedImpulseRotation),WorldInverseInertiaTensors[1]));

 end else begin

  AccumulatedImpulseTranslation:=Vector3Origin;
  AccumulatedImpulseRotation:=Vector3Origin;

 end;

end;

procedure TKraftConstraintJointFixed.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    Jv,Impulse:TKraftVector3;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 (**** Translation ****)

 // Cdot = dot(u, v + cross(w, r))
 Jv:=Vector3Sub(Vector3Add(vB^,Vector3Cross(wB^,RelativePositions[1])),
                    Vector3Add(vA^,Vector3Cross(wA^,RelativePositions[0])));

 Impulse:=Vector3TermMatrixMul(Vector3Neg(Jv),InverseMassMatrixTranslation);

 AccumulatedImpulseTranslation:=Vector3Add(AccumulatedImpulseTranslation,Impulse);

 Vector3DirectSub(vA^,Vector3ScalarMul(Impulse,InverseMasses[0]));
 Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],Impulse),WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(Impulse,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],Impulse),WorldInverseInertiaTensors[1]));

 (**** Rotation ****)

 Jv:=Vector3Sub(wB^,wA^);

 Impulse:=Vector3TermMatrixMul(Vector3Neg(Jv),InverseMassMatrixRotation);

 AccumulatedImpulseRotation:=Vector3Add(AccumulatedImpulseRotation,Impulse);

 Vector3DirectSub(wA^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]));

end;

function TKraftConstraintJointFixed.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,TranslationError,RotationError,Impulse:TKraftVector3;
    InverseMassOfBodies:TKraftScalar;
    SkewSymmetricMatrices:array[0..1] of TKraftMatrix3x3;
    MassMatrix:TKraftMatrix3x3;
    CurrentOrientationDifference,qError:TKraftQuaternion;
begin

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;

 rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 SkewSymmetricMatrices[0]:=GetSkewSymmetricMatrixPlus(rA);
 SkewSymmetricMatrices[1]:=GetSkewSymmetricMatrixPlus(rB);

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  MassMatrix[0,0]:=InverseMassOfBodies;
  MassMatrix[0,1]:=0.0;                              
  MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[0,3]:=0.0;
{$endif}
  MassMatrix[1,0]:=0.0;
  MassMatrix[1,1]:=InverseMassOfBodies;
  MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[1,3]:=0.0;
{$endif}
  MassMatrix[2,0]:=0.0;
  MassMatrix[2,1]:=0.0;
  MassMatrix[2,2]:=InverseMassOfBodies;
{$ifdef SIMD}
  MassMatrix[2,3]:=0.0;
{$endif}
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[0],WorldInverseInertiaTensors[0]),SkewSymmetricMatrices[0]));
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[1],WorldInverseInertiaTensors[1]),SkewSymmetricMatrices[1]));
  InverseMassMatrixTranslation:=Matrix3x3TermInverse(MassMatrix);
 end else begin
  InverseMassMatrixTranslation:=Matrix3x3Null;
 end;

 (**** Translation ****)

 TranslationError:=Vector3Sub(Vector3Add(cB^,rB),Vector3Add(cA^,rA));

 result:=Vector3Length(TranslationError)<Physics.LinearSlop;

 Impulse:=Vector3TermMatrixMul(Vector3Neg(TranslationError),InverseMassMatrixTranslation);

 Vector3DirectSub(cA^,Vector3ScalarMul(Impulse,InverseMasses[0]));
 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(Impulse)),WorldInverseInertiaTensors[0]),1.0);

 Vector3DirectAdd(cB^,Vector3ScalarMul(Impulse,InverseMasses[1]));
 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Vector3Cross(rB,Impulse),WorldInverseInertiaTensors[1]),1.0);

 (**** Rotation ****)

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  InverseMassMatrixRotation:=Matrix3x3TermInverse(Matrix3x3TermAdd(WorldInverseInertiaTensors[0],WorldInverseInertiaTensors[1]));
 end else begin
  InverseMassMatrixRotation:=Matrix3x3Null;
 end;

 CurrentOrientationDifference:=QuaternionTermNormalize(QuaternionMul(qB^,QuaternionInverse(qA^)));
 qError:=QuaternionMul(CurrentOrientationDifference,InverseInitialOrientationDifference);
 RotationError.x:=qError.x*2.0;
 RotationError.y:=qError.y*2.0;
 RotationError.z:=qError.z*2.0;

 result:=result and (Vector3Length(RotationError)<Physics.AngularSlop);

 Impulse:=Vector3TermMatrixMul(Vector3Neg(RotationError),InverseMassMatrixRotation);

 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(Impulse),WorldInverseInertiaTensors[0]),1.0);

 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]),1.0);

end;

function TKraftConstraintJointFixed.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointFixed.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointFixed.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(AccumulatedImpulseTranslation,InverseDeltaTime);
end;

function TKraftConstraintJointFixed.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(AccumulatedImpulseRotation,InverseDeltaTime);
end;

constructor TKraftConstraintJointHinge.Create(const APhysics:TKraft;
                                                      const ARigidBodyA,ARigidBodyB:TKraftRigidBody;
                                                      const AWorldAnchorPoint:TKraftVector3;
                                                      const AWorldRotationAxis:TKraftVector3;
                                                      const ALimitEnabled:boolean=false;
                                                      const AMotorEnabled:boolean=false;
                                                      const AMinimumAngleLimit:TKraftScalar=-1.0;
                                                      const AMaximumAngleLimit:TKraftScalar=1.0;
                                                      const AMotorSpeed:TKraftScalar=0.0;
                                                      const AMaximalMotorTorque:TKraftScalar=0.0;
                                                      const ACollideConnected:boolean=false);
begin

 LimitState:=ALimitEnabled;

 MotorState:=AMotorEnabled;

 LowerLimit:=AMinimumAngleLimit;

 UpperLimit:=AMaximumAngleLimit;

 Assert((LowerLimit<=EPSILON) and (LowerLimit>=(-(pi2+EPSILON))));

 Assert((UpperLimit>=(-EPSILON)) and (UpperLimit<=(pi2+EPSILON)));

 MotorSpeed:=AMotorSpeed;

 MaximalMotorTorque:=AMaximalMotorTorque;

 LocalAnchors[0]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyA.WorldTransform);
 LocalAnchors[1]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyB.WorldTransform);

 LocalAxes[0]:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(AWorldRotationAxis,ARigidBodyA.WorldTransform));
 LocalAxes[1]:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(AWorldRotationAxis,ARigidBodyB.WorldTransform));

 AccumulatedImpulseLowerLimit:=0.0;
 AccumulatedImpulseUpperLimit:=0.0;
 AccumulatedImpulseMotor:=0.0;
 AccumulatedImpulseTranslation:=Vector3Origin;
 AccumulatedImpulseRotation:=Vector2Origin;

 InverseInitialOrientationDifference:=QuaternionInverse(QuaternionTermNormalize(QuaternionMul(ARigidBodyB.Sweep.q0,QuaternionInverse(ARigidBodyA.Sweep.q0))));

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointHinge.Destroy;
begin
 inherited Destroy;
end;

function TKraftConstraintJointHinge.ComputeCurrentHingeAngle(const OrientationA,OrientationB:TKraftQuaternion):TKraftScalar;
 function ComputeNormalizedAngle(a:TKraftScalar):TKraftScalar;
 begin
  result:=a-(floor(a/pi2)*pi2); // ModuloPos(ModuloPos(a+pi,pi2)+pi2,pi2)-pi;
  while result<-pi do begin
   result:=result+pi2;
  end;
  while result>pi do begin
   result:=result-pi2;
  end;
 end;
var CurrentOrientationDifference,RelativeRotation:TKraftQuaternion;
    CosHalfAngle,SinHalfAngleAbs,DotProduct:TKraftScalar;
begin
 // Compute the current orientation difference between the two bodies
 CurrentOrientationDifference:=QuaternionTermNormalize(QuaternionMul(OrientationB,QuaternionInverse(OrientationA)));

 // Compute the relative rotation considering the initial orientation difference
 RelativeRotation:=QuaternionTermNormalize(QuaternionMul(CurrentOrientationDifference,InverseInitialOrientationDifference));

 // Extract cos(theta/2) and |sin(theta/2)|
 CosHalfAngle:=RelativeRotation.w;
 SinHalfAngleAbs:=Vector3Length(PKraftVector3(pointer(@RelativeRotation))^);

 // Compute the dot product of the relative rotation axis and the hinge axis
 DotProduct:=Vector3Dot(PKraftVector3(pointer(@RelativeRotation))^,PKraftVector3(pointer(@A1))^);

 // If the relative rotation axis and the hinge axis are pointing the same direction
 if DotProduct>=0.0 then begin
  result:=2.0*ArcTan2(SinHalfAngleAbs,CosHalfAngle);
 end else begin
  result:=2.0*ArcTan2(SinHalfAngleAbs,-CosHalfAngle);
 end;

 // Convert the angle from range [-2*pi; 2*pi] into the range [-pi; pi]
 result:=ComputeNormalizedAngle(result);

 // Compute and return the corresponding angle near one the two limits
 if LowerLimit<UpperLimit then begin
  if result>UpperLimit then begin
   if abs(ComputeNormalizedAngle(result-UpperLimit))>abs(ComputeNormalizedAngle(result-LowerLimit)) then begin
    result:=result-pi2;
   end;
  end else if result<LowerLimit then begin
   if abs(ComputeNormalizedAngle(UpperLimit-result))<=abs(ComputeNormalizedAngle(LowerLimit-result)) then begin
    result:=result+pi2;
   end;
  end;
 end;

end;

procedure TKraftConstraintJointHinge.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    HingeAngle,LowerLimitError,UpperLimitError,InverseMassOfBodies:TKraftScalar;
    SkewSymmetricMatrices:array[0..1] of TKraftMatrix3x3;
    MassMatrix:TKraftMatrix3x3;
    RotationKMatrix:TKraftMatrix2x2;
    OldIsLowerLimitViolated,OldIsUpperLimitViolated:boolean;
    a2,b2,c2,I1B2CrossA1,I1C2CrossA1,I2B2CrossA1,I2C2CrossA1,RotationImpulse,LimitsImpulse,MotorImpulse,AngularImpulse:TKraftVector3;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 HingeAngle:=ComputeCurrentHingeAngle(qA^,qB^);

 LowerLimitError:=HingeAngle-LowerLimit;
 UpperLimitError:=UpperLimit-HingeAngle;
 OldIsLowerLimitViolated:=IsLowerLimitViolated;
 IsLowerLimitViolated:=LowerLimitError<=0.0;
 if IsLowerLimitViolated<>OldIsLowerLimitViolated then begin
  AccumulatedImpulseLowerLimit:=0.0;
 end;
 OldIsUpperLimitViolated:=IsUpperLimitViolated;
 IsUpperLimitViolated:=UpperLimitError<=0.0;
 if IsUpperLimitViolated<>OldIsUpperLimitViolated then begin
  AccumulatedImpulseUpperLimit:=0.0;
 end;

 a1:=Vector3NormEx(Vector3TermQuaternionRotate(LocalAxes[0],qA^));
 a2:=Vector3NormEx(Vector3TermQuaternionRotate(LocalAxes[1],qB^));
 b2:=Vector3GetOneUnitOrthogonalVector(a2);
 c2:=Vector3Cross(a2,b2);
 B2CrossA1:=Vector3Cross(b2,a1);
 C2CrossA1:=Vector3Cross(c2,a1);

 SkewSymmetricMatrices[0]:=GetSkewSymmetricMatrixPlus(RelativePositions[0]);
 SkewSymmetricMatrices[1]:=GetSkewSymmetricMatrixPlus(RelativePositions[1]);

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  MassMatrix[0,0]:=InverseMassOfBodies;
  MassMatrix[0,1]:=0.0;
  MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[0,3]:=0.0;
{$endif}
  MassMatrix[1,0]:=0.0;
  MassMatrix[1,1]:=InverseMassOfBodies;
  MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[1,3]:=0.0;
{$endif}
  MassMatrix[2,0]:=0.0;
  MassMatrix[2,1]:=0.0;
  MassMatrix[2,2]:=InverseMassOfBodies;
{$ifdef SIMD}
  MassMatrix[2,3]:=0.0;
{$endif}
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[0],WorldInverseInertiaTensors[0]),SkewSymmetricMatrices[0]));
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[1],WorldInverseInertiaTensors[1]),SkewSymmetricMatrices[1]));
  InverseMassMatrixTranslation:=Matrix3x3TermInverse(MassMatrix);
 end else begin
  InverseMassMatrixTranslation:=Matrix3x3Null;
 end;

 I1B2CrossA1:=Vector3TermMatrixMul(B2CrossA1,WorldInverseInertiaTensors[0]);
 I1C2CrossA1:=Vector3TermMatrixMul(C2CrossA1,WorldInverseInertiaTensors[0]);
 I2B2CrossA1:=Vector3TermMatrixMul(B2CrossA1,WorldInverseInertiaTensors[1]);
 I2C2CrossA1:=Vector3TermMatrixMul(C2CrossA1,WorldInverseInertiaTensors[1]);
 RotationKMatrix[0,0]:=Vector3Dot(B2CrossA1,I1B2CrossA1)+Vector3Dot(B2CrossA1,I2B2CrossA1);
 RotationKMatrix[0,1]:=Vector3Dot(B2CrossA1,I1C2CrossA1)+Vector3Dot(B2CrossA1,I2C2CrossA1);
 RotationKMatrix[1,0]:=Vector3Dot(C2CrossA1,I1B2CrossA1)+Vector3Dot(C2CrossA1,I2B2CrossA1);
 RotationKMatrix[1,1]:=Vector3Dot(C2CrossA1,I1C2CrossA1)+Vector3Dot(C2CrossA1,I2C2CrossA1);
 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  Matrix2x2Inverse(InverseMassMatrixRotation,RotationKMatrix);
 end else begin
  InverseMassMatrixRotation:=Matrix2x2Null;
 end;

 if MotorState or (LimitState and (IsLowerLimitViolated or IsUpperLimitViolated)) then begin
  // Compute the inverse of the mass matrix K=JM^-1J^t for the limits and motor (1x1 matrix)
  InverseMassMatrixLimitMotor:=Vector3Dot(a1,Vector3TermMatrixMul(a1,WorldInverseInertiaTensors[0]))+
                               Vector3Dot(a1,Vector3TermMatrixMul(a1,WorldInverseInertiaTensors[1]));
  if InverseMassMatrixLimitMotor>0.0 then begin
   InverseMassMatrixLimitMotor:=1.0/InverseMassMatrixLimitMotor;
  end else begin
   InverseMassMatrixLimitMotor:=0.0;
  end;
 end;

 if Physics.WarmStarting then begin

  // Compute the impulse P=J^T * lambda for the 2 rotation constraints
  RotationImpulse:=Vector3Add(Vector3ScalarMul(B2CrossA1,AccumulatedImpulseRotation.x),
                                  Vector3ScalarMul(C2CrossA1,AccumulatedImpulseRotation.y));

  // Compute the impulse P=J^T * lambda for the lower and upper limits constraints
  LimitsImpulse:=Vector3ScalarMul(a1,AccumulatedImpulseLowerLimit-AccumulatedImpulseUpperLimit);

  // Compute the impulse P=J^T * lambda for the motor constraint
  MotorImpulse:=Vector3ScalarMul(a1,AccumulatedImpulseMotor);

  AccumulatedImpulseTranslation:=Vector3ScalarMul(AccumulatedImpulseTranslation,TimeStep.DeltaTimeRatio);

  AngularImpulse:=Vector3ScalarMul(Vector3Add(Vector3Add(RotationImpulse,LimitsImpulse),MotorImpulse),TimeStep.DeltaTimeRatio);

  Vector3DirectSub(vA^,Vector3ScalarMul(AccumulatedImpulseTranslation,InverseMasses[0]));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Add(Vector3Cross(RelativePositions[0],AccumulatedImpulseTranslation),AngularImpulse),WorldInverseInertiaTensors[0]));

  Vector3DirectAdd(vB^,Vector3ScalarMul(AccumulatedImpulseTranslation,InverseMasses[1]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Add(Vector3Cross(RelativePositions[1],AccumulatedImpulseTranslation),AngularImpulse),WorldInverseInertiaTensors[1]));

 end else begin

  AccumulatedImpulseTranslation:=Vector3Origin;
  AccumulatedImpulseRotation:=Vector2Origin;
  AccumulatedImpulseLowerLimit:=0.0;
  AccumulatedImpulseUpperLimit:=0.0;
  AccumulatedImpulseMotor:=0.0;

 end;

end;

procedure TKraftConstraintJointHinge.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    vpA,vpB,Jv,Impulse:TKraftVector3;
    JvRotation,RotationImpulse:TKraftVector2;
    JvLowerLimit,ImpulseLower,JvUpperLimit,ImpulseUpper,JvMotor,ImpulseMotor,LambdaTemp,MaximalMotorImpulse:TKraftScalar;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 (**** Translation ****)

 // Cdot = dot(u, v + cross(w, r))
 vpA:=Vector3Add(vA^,Vector3Cross(wA^,RelativePositions[0]));
 vpB:=Vector3Add(vB^,Vector3Cross(wB^,RelativePositions[1]));
 Jv:=Vector3Sub(vpB,vpA);

 Impulse:=Vector3TermMatrixMul(Vector3Neg(Jv),InverseMassMatrixTranslation);

 AccumulatedImpulseTranslation:=Vector3Add(AccumulatedImpulseTranslation,Impulse);

 Vector3DirectSub(vA^,Vector3ScalarMul(Impulse,InverseMasses[0]));
 Vector3DirectSub(wA^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[0],Impulse),WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(Impulse,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Vector3Cross(RelativePositions[1],Impulse),WorldInverseInertiaTensors[1]));

 (**** Rotation ****)

 JvRotation.x:=Vector3Dot(B2CrossA1,wB^)-Vector3Dot(B2CrossA1,wA^);
 JvRotation.y:=Vector3Dot(C2CrossA1,wB^)-Vector3Dot(C2CrossA1,wA^);

 RotationImpulse.x:=-((JvRotation.x*InverseMassMatrixRotation[0,0])+(JvRotation.y*InverseMassMatrixRotation[0,1]));
 RotationImpulse.y:=-((JvRotation.x*InverseMassMatrixRotation[1,0])+(JvRotation.y*InverseMassMatrixRotation[1,1]));

 AccumulatedImpulseRotation.x:=AccumulatedImpulseRotation.x+RotationImpulse.x;
 AccumulatedImpulseRotation.y:=AccumulatedImpulseRotation.y+RotationImpulse.y;

 Impulse:=Vector3Add(Vector3ScalarMul(B2CrossA1,RotationImpulse.x),
                         Vector3ScalarMul(C2CrossA1,RotationImpulse.y));

 Vector3DirectSub(wA^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(wB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]));

 (**** Limits ****)

 if LimitState then begin
  if IsLowerLimitViolated then begin
   JvLowerLimit:=Vector3Dot(Vector3Sub(wB^,wA^),a1);
   ImpulseLower:=InverseMassMatrixLimitMotor*(-JvLowerLimit);
   LambdaTemp:=AccumulatedImpulseLowerLimit;
   AccumulatedImpulseLowerLimit:=Max(0.0,AccumulatedImpulseLowerLimit+ImpulseLower);
   ImpulseLower:=AccumulatedImpulseLowerLimit-LambdaTemp;
   Impulse:=Vector3ScalarMul(a1,ImpulseLower);
   Vector3DirectSub(wA^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[0]));
   Vector3DirectAdd(wB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]));
  end;
  if IsUpperLimitViolated then begin
   JvUpperLimit:=-Vector3Dot(Vector3Sub(wB^,wA^),a1);
   ImpulseUpper:=InverseMassMatrixLimitMotor*(-JvUpperLimit);
   LambdaTemp:=AccumulatedImpulseUpperLimit;
   AccumulatedImpulseUpperLimit:=Max(0.0,AccumulatedImpulseUpperLimit+ImpulseUpper);
   ImpulseUpper:=-(AccumulatedImpulseUpperLimit-LambdaTemp);
   Impulse:=Vector3ScalarMul(a1,ImpulseUpper);
   Vector3DirectSub(wA^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[0]));
   Vector3DirectAdd(wB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]));
  end;
 end;

 (**** Motor ****)

 if MotorState then begin
  JvMotor:=Vector3Dot(Vector3Sub(wB^,wA^),a1);
  ImpulseMotor:=InverseMassMatrixLimitMotor*(-JvMotor);
  LambdaTemp:=AccumulatedImpulseMotor;
  MaximalMotorImpulse:=MaximalMotorTorque*TimeStep.DeltaTime;
  AccumulatedImpulseMotor:=Min(Max(AccumulatedImpulseMotor+ImpulseMotor,-MaximalMotorImpulse),MaximalMotorImpulse);
  ImpulseMotor:=AccumulatedImpulseMotor-LambdaTemp;
  Impulse:=Vector3ScalarMul(a1,ImpulseMotor);
  Vector3DirectSub(wA^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[0]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]));
 end;

end;

function TKraftConstraintJointHinge.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,TranslationError,Impulse,a2,b2,c2,I1B2CrossA1,I1C2CrossA1,I2B2CrossA1,I2C2CrossA1:TKraftVector3;
    RotationError,RotationImpulse:TKraftVector2;
    InverseMassOfBodies,HingeAngle,LowerLimitError,UpperLimitError,ImpulseLower,ImpulseUpper:TKraftScalar;
    SkewSymmetricMatrices:array[0..1] of TKraftMatrix3x3;
    MassMatrix:TKraftMatrix3x3;
    RotationKMatrix:TKraftMatrix2x2;
begin

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;

 rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 HingeAngle:=ComputeCurrentHingeAngle(qA^,qB^);

 LowerLimitError:=HingeAngle-LowerLimit;
 UpperLimitError:=UpperLimit-HingeAngle;
 IsLowerLimitViolated:=LowerLimitError<=0.0;
 IsUpperLimitViolated:=UpperLimitError<=0.0;

 a1:=Vector3NormEx(Vector3TermQuaternionRotate(LocalAxes[0],qA^));
 a2:=Vector3NormEx(Vector3TermQuaternionRotate(LocalAxes[1],qB^));
 b2:=Vector3GetOneUnitOrthogonalVector(a2);
 c2:=Vector3Cross(a2,b2);
 B2CrossA1:=Vector3Cross(b2,a1);
 C2CrossA1:=Vector3Cross(c2,a1);

 SkewSymmetricMatrices[0]:=GetSkewSymmetricMatrixPlus(rA);
 SkewSymmetricMatrices[1]:=GetSkewSymmetricMatrixPlus(rB);

 (**** Translation ****)

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  MassMatrix[0,0]:=InverseMassOfBodies;
  MassMatrix[0,1]:=0.0;
  MassMatrix[0,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[0,3]:=0.0;
{$endif}
  MassMatrix[1,0]:=0.0;
  MassMatrix[1,1]:=InverseMassOfBodies;
  MassMatrix[1,2]:=0.0;
{$ifdef SIMD}
  MassMatrix[1,3]:=0.0;
{$endif}
  MassMatrix[2,0]:=0.0;
  MassMatrix[2,1]:=0.0;
  MassMatrix[2,2]:=InverseMassOfBodies;
{$ifdef SIMD}
  MassMatrix[2,3]:=0.0;
{$endif}
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[0],WorldInverseInertiaTensors[0]),SkewSymmetricMatrices[0]));
  Matrix3x3Add(MassMatrix,Matrix3x3TermMulTranspose(Matrix3x3TermMul(SkewSymmetricMatrices[1],WorldInverseInertiaTensors[1]),SkewSymmetricMatrices[1]));
  InverseMassMatrixTranslation:=Matrix3x3TermInverse(MassMatrix);
 end else begin
  InverseMassMatrixTranslation:=Matrix3x3Null;
 end;

 TranslationError:=Vector3Sub(Vector3Add(cB^,rB),Vector3Add(cA^,rA));

 result:=Vector3Length(TranslationError)<Physics.LinearSlop;

 Impulse:=Vector3TermMatrixMul(Vector3Neg(TranslationError),InverseMassMatrixTranslation);

 Vector3DirectSub(cA^,Vector3ScalarMul(Impulse,InverseMasses[0]));
 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(Impulse)),WorldInverseInertiaTensors[0]),1.0);

 Vector3DirectAdd(cB^,Vector3ScalarMul(Impulse,InverseMasses[1]));
 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Vector3Cross(rB,Impulse),WorldInverseInertiaTensors[1]),1.0);

 (**** Rotation ****)

 I1B2CrossA1:=Vector3TermMatrixMul(B2CrossA1,WorldInverseInertiaTensors[0]);
 I1C2CrossA1:=Vector3TermMatrixMul(C2CrossA1,WorldInverseInertiaTensors[0]);
 I2B2CrossA1:=Vector3TermMatrixMul(B2CrossA1,WorldInverseInertiaTensors[1]);
 I2C2CrossA1:=Vector3TermMatrixMul(C2CrossA1,WorldInverseInertiaTensors[1]);
 RotationKMatrix[0,0]:=Vector3Dot(B2CrossA1,I1B2CrossA1)+Vector3Dot(B2CrossA1,I2B2CrossA1);
 RotationKMatrix[0,1]:=Vector3Dot(B2CrossA1,I1C2CrossA1)+Vector3Dot(B2CrossA1,I2C2CrossA1);
 RotationKMatrix[1,0]:=Vector3Dot(C2CrossA1,I1B2CrossA1)+Vector3Dot(C2CrossA1,I2B2CrossA1);
 RotationKMatrix[1,1]:=Vector3Dot(C2CrossA1,I1C2CrossA1)+Vector3Dot(C2CrossA1,I2C2CrossA1);
 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  Matrix2x2Inverse(InverseMassMatrixRotation,RotationKMatrix);
 end else begin
  InverseMassMatrixRotation:=Matrix2x2Null;
 end;

 RotationError.x:=Vector3Dot(a1,b2);
 RotationError.y:=Vector3Dot(a1,c2);            

 result:=result and (Vector2Length(RotationError)<Physics.AngularSlop);

 RotationImpulse.x:=-((RotationError.x*InverseMassMatrixRotation[0,0])+(RotationError.y*InverseMassMatrixRotation[0,1]));
 RotationImpulse.y:=-((RotationError.x*InverseMassMatrixRotation[1,0])+(RotationError.y*InverseMassMatrixRotation[1,1]));

 Impulse:=Vector3Add(Vector3ScalarMul(B2CrossA1,RotationImpulse.x),Vector3ScalarMul(C2CrossA1,RotationImpulse.y));

 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(Impulse),WorldInverseInertiaTensors[0]),1.0);

 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]),1.0);

 (**** Limits ****)
 
 if LimitState then begin
  if IsLowerLimitViolated then begin
   ImpulseLower:=InverseMassMatrixLimitMotor*(-LowerLimitError);
   result:=result and (ImpulseLower<Physics.AngularSlop);
   Impulse:=Vector3ScalarMul(a1,ImpulseLower);
   QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(Impulse),WorldInverseInertiaTensors[0]),1.0);
   QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]),1.0);
  end;
  if IsUpperLimitViolated then begin
   ImpulseUpper:=InverseMassMatrixLimitMotor*(-UpperLimitError);
   result:=result and (ImpulseUpper<Physics.AngularSlop);
   Impulse:=Vector3ScalarMul(a1,-ImpulseUpper);
   QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(Impulse),WorldInverseInertiaTensors[0]),1.0);
   QuaternionDirectSpin(qB^,Vector3TermMatrixMul(Impulse,WorldInverseInertiaTensors[1]),1.0);
  end;
 end;

end;

function TKraftConstraintJointHinge.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointHinge.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointHinge.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(AccumulatedImpulseTranslation,InverseDeltaTime);
end;

function TKraftConstraintJointHinge.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
var RotationImpulse,LimitsImpulse,MotorImpulse:TKraftVector3;
begin
 RotationImpulse:=Vector3Sub(Vector3ScalarMul(C2CrossA1,AccumulatedImpulseRotation.y),
                                  Vector3ScalarMul(B2CrossA1,-AccumulatedImpulseRotation.x));
 LimitsImpulse:=Vector3ScalarMul(a1,AccumulatedImpulseLowerLimit-AccumulatedImpulseUpperLimit);
 MotorImpulse:=Vector3ScalarMul(a1,AccumulatedImpulseMotor);
 result:=Vector3ScalarMul(Vector3Add(Vector3Add(RotationImpulse,LimitsImpulse),MotorImpulse),InverseDeltaTime);
end;

function TKraftConstraintJointHinge.IsLimitEnabled:boolean;
begin
 result:=LimitState;
end;

function TKraftConstraintJointHinge.IsMotorEnabled:boolean;
begin
 result:=MotorState;
end;

function TKraftConstraintJointHinge.GetMinimumAngleLimit:TKraftScalar;
begin
 result:=LowerLimit;
end;

function TKraftConstraintJointHinge.GetMaximumAngleLimit:TKraftScalar;
begin
 result:=UpperLimit;
end;

function TKraftConstraintJointHinge.GetMotorSpeed:TKraftScalar;
begin
 result:=MotorSpeed;
end;

function TKraftConstraintJointHinge.GetMaximalMotorTorque:TKraftScalar;
begin
 result:=MaximalMotorTorque;
end;

function TKraftConstraintJointHinge.GetMotorTorque(const DeltaTime:TKraftScalar):TKraftScalar;
begin
 result:=AccumulatedImpulseMotor/DeltaTime;
end;

procedure TKraftConstraintJointHinge.ResetLimits;
begin
 AccumulatedImpulseLowerLimit:=0.0;
 AccumulatedImpulseUpperLimit:=0.0;
 RigidBodies[0].SetToAwake;
 RigidBodies[1].SetToAwake;
end;

procedure TKraftConstraintJointHinge.EnableLimit(const ALimitEnabled:boolean);
begin
 if LimitState<>ALimitEnabled then begin
  LimitState:=ALimitEnabled;
  ResetLimits;
 end;
end;

procedure TKraftConstraintJointHinge.EnableMotor(const AMotorEnabled:boolean);
begin
 if MotorState<>AMotorEnabled then begin
  MotorState:=AMotorEnabled;
  AccumulatedImpulseMotor:=0.0;
  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;
 end;
end;

procedure TKraftConstraintJointHinge.SetMinimumAngleLimit(const AMinimumAngleLimit:TKraftScalar);
begin
 if LowerLimit<>AMinimumAngleLimit then begin
  LowerLimit:=AMinimumAngleLimit;
  Assert((LowerLimit<=EPSILON) and (LowerLimit>=(-(pi2+EPSILON))));
  ResetLimits;
 end;
end;

procedure TKraftConstraintJointHinge.SetMaximumAngleLimit(const AMaximumAngleLimit:TKraftScalar);
begin
 if UpperLimit<>AMaximumAngleLimit then begin
  UpperLimit:=AMaximumAngleLimit;
  Assert((UpperLimit>=(-EPSILON)) and (UpperLimit<=(pi2+EPSILON)));
  ResetLimits;
 end;
end;

procedure TKraftConstraintJointHinge.SetMotorSpeed(const AMotorSpeed:TKraftScalar);
begin
 if MotorSpeed<>AMotorSpeed then begin
  MotorSpeed:=AMotorSpeed;
  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;
 end;
end;

procedure TKraftConstraintJointHinge.SetMaximalMotorTorque(const AMaximalMotorTorque:TKraftScalar);
begin
 if MaximalMotorTorque<>AMaximalMotorTorque then begin
  MaximalMotorTorque:=AMaximalMotorTorque;
  Assert(MaximalMotorTorque>=(-EPSILON));
  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;
 end;
end;

constructor TKraftConstraintJointSlider.Create(const APhysics:TKraft;
                                                       const ARigidBodyA,ARigidBodyB:TKraftRigidBody;
                                                       const AWorldAnchorPoint:TKraftVector3;
                                                       const AWorldSliderAxis:TKraftVector3;
                                                       const ALimitEnabled:boolean=false;
                                                       const AMotorEnabled:boolean=false;
                                                       const AMinimumTranslationLimit:TKraftScalar=-1.0;
                                                       const AMaximumTranslationLimit:TKraftScalar=1.0;
                                                       const AMotorSpeed:TKraftScalar=0.0;
                                                       const AMaximalMotorForce:TKraftScalar=0.0;
                                                       const ACollideConnected:boolean=false);
begin

 LimitState:=ALimitEnabled;

 MotorState:=AMotorEnabled;

 LowerLimit:=AMinimumTranslationLimit;

 UpperLimit:=AMaximumTranslationLimit;

 MotorSpeed:=AMotorSpeed;

 MaximalMotorForce:=AMaximalMotorForce;

 LocalAnchors[0]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyA.WorldTransform);
 LocalAnchors[1]:=Vector3TermMatrixMulInverted(AWorldAnchorPoint,ARigidBodyB.WorldTransform);

 SliderAxisBodyA:=Vector3NormEx(Vector3TermMatrixMulTransposedBasis(AWorldSliderAxis,ARigidBodyA.WorldTransform));

 AccumulatedImpulseLowerLimit:=0.0;
 AccumulatedImpulseUpperLimit:=0.0;
 AccumulatedImpulseMotor:=0.0;
 AccumulatedImpulseTranslation:=Vector2Origin;
 AccumulatedImpulseRotation:=Vector3Origin;

 InverseInitialOrientationDifference:=QuaternionInverse(QuaternionTermNormalize(QuaternionMul(ARigidBodyB.Sweep.q0,QuaternionInverse(ARigidBodyA.Sweep.q0))));

 if ACollideConnected then begin
  Include(Flags,kcfCollideConnected);
 end else begin
  Exclude(Flags,kcfCollideConnected);
 end;

 RigidBodies[0]:=ARigidBodyA;
 RigidBodies[1]:=ARigidBodyB;

 inherited Create(APhysics);

end;

destructor TKraftConstraintJointSlider.Destroy;
begin
 inherited Destroy;
end;

procedure TKraftConstraintJointSlider.InitializeConstraintsAndWarmStart(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var cA,vA,wA,cB,vB,wB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    uDotSliderAxis,LowerLimitError,UpperLimitError,InverseMassOfBodies,ImpulseLimits:TKraftScalar;
    TranslationKMatrix:TKraftMatrix2x2;
    OldIsLowerLimitViolated,OldIsUpperLimitViolated:boolean;
    u,R1PlusU,I1R1PlusUCrossN1,I1R1PlusUCrossN2,I2R2CrossN1,I2R2CrossN2,
    LinearImpulseLimits,ImpulseMotor,LinearImpulse,AngularImpulseA,AngularImpulseB:TKraftVector3;
begin

 IslandIndices[0]:=RigidBodies[0].IslandIndices[Island.IslandIndex];
 IslandIndices[1]:=RigidBodies[1].IslandIndices[Island.IslandIndex];

 LocalCenters[0]:=RigidBodies[0].Sweep.LocalCenter;
 LocalCenters[1]:=RigidBodies[1].Sweep.LocalCenter;

 InverseMasses[0]:=RigidBodies[0].InverseMass;
 InverseMasses[1]:=RigidBodies[1].InverseMass;

 WorldInverseInertiaTensors[0]:=RigidBodies[0].WorldInverseInertiaTensor;
 WorldInverseInertiaTensors[1]:=RigidBodies[1].WorldInverseInertiaTensor;

 SolverVelocities[0]:=@Island.Solver.Velocities[IslandIndices[0]];
 SolverVelocities[1]:=@Island.Solver.Velocities[IslandIndices[1]];

 SolverPositions[0]:=@Island.Solver.Positions[IslandIndices[0]];
 SolverPositions[1]:=@Island.Solver.Positions[IslandIndices[1]];

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;
 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;
 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 RelativePositions[0]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 RelativePositions[1]:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);
 u:=Vector3Sub(Vector3Add(cB^,RelativePositions[1]),Vector3Add(cA^,RelativePositions[0]));

 SliderAxisWorld:=Vector3NormEx(Vector3TermQuaternionRotate(SliderAxisBodyA,qA^));

 N1:=Vector3GetOneUnitOrthogonalVector(SliderAxisWorld);
 N2:=Vector3Cross(SliderAxisWorld,N1);

 uDotSliderAxis:=Vector3Dot(u,SliderAxisWorld);

 LowerLimitError:=uDotSliderAxis-LowerLimit;
 UpperLimitError:=UpperLimit-uDotSliderAxis;
 OldIsLowerLimitViolated:=IsLowerLimitViolated;
 IsLowerLimitViolated:=LowerLimitError<=0.0;
 if IsLowerLimitViolated<>OldIsLowerLimitViolated then begin
  AccumulatedImpulseLowerLimit:=0.0;
 end;
 OldIsUpperLimitViolated:=IsUpperLimitViolated;
 IsUpperLimitViolated:=UpperLimitError<=0.0;
 if IsUpperLimitViolated<>OldIsUpperLimitViolated then begin
  AccumulatedImpulseUpperLimit:=0.0;
 end;

 R2CrossN1:=Vector3Cross(RelativePositions[1],N1);
 R2CrossN2:=Vector3Cross(RelativePositions[1],N2);
 R2CrossSliderAxis:=Vector3Cross(RelativePositions[1],SliderAxisWorld);
 R1PlusU:=Vector3Cross(RelativePositions[0],u);
 R1PlusUCrossN1:=Vector3Cross(R1PlusU,N1);
 R1PlusUCrossN2:=Vector3Cross(R1PlusU,N2);
 R1PlusUCrossSliderAxis:=Vector3Cross(R1PlusU,SliderAxisWorld);

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 I1R1PlusUCrossN1:=Vector3TermMatrixMul(R1PlusUCrossN1,WorldInverseInertiaTensors[0]);
 I1R1PlusUCrossN2:=Vector3TermMatrixMul(R1PlusUCrossN2,WorldInverseInertiaTensors[0]);
 I2R2CrossN1:=Vector3TermMatrixMul(R2CrossN1,WorldInverseInertiaTensors[1]);
 I2R2CrossN2:=Vector3TermMatrixMul(R2CrossN2,WorldInverseInertiaTensors[1]);
 TranslationKMatrix[0,0]:=InverseMassOfBodies+Vector3Dot(R1PlusUCrossN1,I1R1PlusUCrossN1)+Vector3Dot(R2CrossN1,I2R2CrossN1);
 TranslationKMatrix[0,1]:=Vector3Dot(R1PlusUCrossN1,I1R1PlusUCrossN2)+Vector3Dot(R2CrossN1,I2R2CrossN2);
 TranslationKMatrix[1,0]:=Vector3Dot(R1PlusUCrossN2,I1R1PlusUCrossN1)+Vector3Dot(R2CrossN2,I2R2CrossN1);
 TranslationKMatrix[1,1]:=InverseMassOfBodies+Vector3Dot(R1PlusUCrossN2,I1R1PlusUCrossN2)+Vector3Dot(R2CrossN2,I2R2CrossN2);
 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  Matrix2x2Inverse(InverseMassMatrixTranslationConstraint,TranslationKMatrix);
  InverseMassMatrixRotationConstraint:=Matrix3x3TermInverse(Matrix3x3TermAdd(WorldInverseInertiaTensors[0],WorldInverseInertiaTensors[1]));
 end else begin
  InverseMassMatrixTranslationConstraint:=Matrix2x2Null;
  InverseMassMatrixRotationConstraint:=Matrix3x3Null;
 end;

 if LimitState and (IsLowerLimitViolated or IsUpperLimitViolated) then begin
  // Compute the inverse of the mass matrix K=JM^-1J^t for the limits (1x1 matrix)
  InverseMassMatrixLimit:=InverseMassOfBodies+
                          Vector3Dot(R1PlusUCrossSliderAxis,Vector3TermMatrixMul(R1PlusUCrossSliderAxis,WorldInverseInertiaTensors[0]))+
                          Vector3Dot(R2CrossSliderAxis,Vector3TermMatrixMul(R2CrossSliderAxis,WorldInverseInertiaTensors[1]));
  if InverseMassMatrixLimit>0.0 then begin
   InverseMassMatrixLimit:=1.0/InverseMassMatrixLimit;
  end else begin
   InverseMassMatrixLimit:=0.0;
  end;
 end;
            
 if MotorState then begin
  // Compute the inverse of the mass matrix K=JM^-1J^t for the motor (1x1 matrix)
  InverseMassMatrixMotor:=InverseMassOfBodies;
  if InverseMassMatrixMotor>0.0 then begin
   InverseMassMatrixMotor:=1.0/InverseMassMatrixMotor;
  end else begin
   InverseMassMatrixMotor:=0.0;
  end;
 end;

 if Physics.WarmStarting then begin

    // Compute the impulse P=J^T * lambda for the lower and upper limits constraints of body A
  ImpulseLimits:=AccumulatedImpulseLowerLimit-AccumulatedImpulseUpperLimit;
  LinearImpulseLimits:=Vector3ScalarMul(SliderAxisWorld,ImpulseLimits);

  // Compute the impulse P=J^T * lambda for the motor constraint of body 1
  ImpulseMotor:=Vector3ScalarMul(SliderAxisWorld,-AccumulatedImpulseMotor);

  // Compute the linear impulse P=J^T * lambda for the 2 translation constraints for bodies A and B
  LinearImpulse:=Vector3ScalarMul(Vector3Add(Vector3Add(Vector3ScalarMul(N1,AccumulatedImpulseTranslation.x),
                                                                    Vector3ScalarMul(N2,AccumulatedImpulseTranslation.y)),
                                                     Vector3Add(LinearImpulseLimits,ImpulseMotor)),TimeStep.DeltaTimeRatio);

  // Compute the angular impulse P=J^T * lambda for the 2 translation constraints for body A
  AngularImpulseA:=Vector3ScalarMul(Vector3Add(Vector3Add(Vector3ScalarMul(R1PlusUCrossN1,AccumulatedImpulseTranslation.x),
                                                                      Vector3ScalarMul(R1PlusUCrossN2,AccumulatedImpulseTranslation.y)),
                                                       Vector3Add(Vector3ScalarMul(R1PlusUCrossSliderAxis,ImpulseLimits),
                                                                      AccumulatedImpulseRotation)),TimeStep.DeltaTimeRatio);

  // Compute the angular impulse P=J^T * lambda for the 2 translation constraints for body B
  AngularImpulseB:=Vector3ScalarMul(Vector3Add(Vector3Add(Vector3ScalarMul(R2CrossN1,AccumulatedImpulseTranslation.x),
                                                                      Vector3ScalarMul(R2CrossN2,AccumulatedImpulseTranslation.y)),
                                                       Vector3Add(Vector3ScalarMul(R2CrossSliderAxis,ImpulseLimits),
                                                                      AccumulatedImpulseRotation)),TimeStep.DeltaTimeRatio);

  // Apply impulses
  Vector3DirectSub(vA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
  Vector3DirectSub(wA^,Vector3TermMatrixMul(AngularImpulseA,WorldInverseInertiaTensors[0]));

  Vector3DirectAdd(vB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]));

 end else begin

  AccumulatedImpulseTranslation:=Vector2Origin;
  AccumulatedImpulseRotation:=Vector3Origin;
  AccumulatedImpulseLowerLimit:=0.0;
  AccumulatedImpulseUpperLimit:=0.0;
  AccumulatedImpulseMotor:=0.0;

 end;

end;                             

procedure TKraftConstraintJointSlider.SolveVelocityConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep);
var vA,wA,vB,wB:PKraftVector3;
    LinearImpulse,AngularImpulseA,AngularImpulseB,JvRotation,RotationImpulse:TKraftVector3;
    JvTranslation,TranslationImpulse:TKraftVector2;
    JvLowerLimit,ImpulseLower,JvUpperLimit,ImpulseUpper,JvMotor,ImpulseMotor,LambdaTemp,MaximalMotorImpulse:TKraftScalar;
begin

 vA:=@SolverVelocities[0]^.LinearVelocity;
 wA:=@SolverVelocities[0]^.AngularVelocity;

 vB:=@SolverVelocities[1]^.LinearVelocity;
 wB:=@SolverVelocities[1]^.AngularVelocity;

 (**** Translation ****)

 // Compute J*v for the 2 translation constraints
 JvTranslation.x:=(Vector3Dot(N1,vB^)+Vector3Dot(wB^,R2CrossN1))-(Vector3Dot(N1,vA^)+Vector3Dot(wA^,R1PlusUCrossN1));
 JvTranslation.y:=(Vector3Dot(N2,vB^)+Vector3Dot(wB^,R2CrossN2))-(Vector3Dot(N2,vA^)+Vector3Dot(wA^,R1PlusUCrossN2));

 TranslationImpulse.x:=-((JvTranslation.x*InverseMassMatrixTranslationConstraint[0,0])+(JvTranslation.y*InverseMassMatrixTranslationConstraint[0,1]));
 TranslationImpulse.y:=-((JvTranslation.x*InverseMassMatrixTranslationConstraint[1,0])+(JvTranslation.y*InverseMassMatrixTranslationConstraint[1,1]));

 AccumulatedImpulseTranslation.x:=AccumulatedImpulseTranslation.x+TranslationImpulse.x;
 AccumulatedImpulseTranslation.y:=AccumulatedImpulseTranslation.y+TranslationImpulse.y;

 LinearImpulse:=Vector3Add(Vector3ScalarMul(N1,TranslationImpulse.x),
                               Vector3ScalarMul(N2,TranslationImpulse.y));

 AngularImpulseA:=Vector3Add(Vector3ScalarMul(R1PlusUCrossN1,TranslationImpulse.x),
                                 Vector3ScalarMul(R1PlusUCrossN2,TranslationImpulse.y));

 AngularImpulseB:=Vector3Add(Vector3ScalarMul(R2CrossN1,TranslationImpulse.x),
                                 Vector3ScalarMul(R2CrossN2,TranslationImpulse.y));

 Vector3DirectSub(vA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
 Vector3DirectSub(wA^,Vector3TermMatrixMul(AngularImpulseA,WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(vB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
 Vector3DirectAdd(wB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]));

 (**** Rotation ****)

 JvRotation:=Vector3Sub(wB^,wA^);

 RotationImpulse:=Vector3TermMatrixMul(Vector3Neg(JvRotation),InverseMassMatrixRotationConstraint);

 Vector3DirectAdd(AccumulatedImpulseRotation,RotationImpulse);

 Vector3DirectSub(wA^,Vector3TermMatrixMul(RotationImpulse,WorldInverseInertiaTensors[0]));

 Vector3DirectAdd(wB^,Vector3TermMatrixMul(RotationImpulse,WorldInverseInertiaTensors[1]));

 (**** Limits ****)

 if LimitState then begin
  if IsLowerLimitViolated then begin
   JvLowerLimit:=(Vector3Dot(SliderAxisWorld,vB^)+Vector3Dot(R2CrossSliderAxis,wB^))-(Vector3Dot(SliderAxisWorld,vA^)+Vector3Dot(R1PlusUCrossSliderAxis,wA^));
   ImpulseLower:=InverseMassMatrixLimit*(-JvLowerLimit);
   LambdaTemp:=AccumulatedImpulseLowerLimit;
   AccumulatedImpulseLowerLimit:=Max(0.0,AccumulatedImpulseLowerLimit+ImpulseLower);
   ImpulseLower:=AccumulatedImpulseLowerLimit-LambdaTemp;
   LinearImpulse:=Vector3ScalarMul(SliderAxisWorld,ImpulseLower);
   AngularImpulseA:=Vector3ScalarMul(R1PlusUCrossSliderAxis,ImpulseLower);
   AngularImpulseB:=Vector3ScalarMul(R2CrossSliderAxis,ImpulseLower);
   Vector3DirectSub(vA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
   Vector3DirectSub(wA^,Vector3TermMatrixMul(AngularImpulseA,WorldInverseInertiaTensors[0]));
   Vector3DirectAdd(vB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
   Vector3DirectAdd(wB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]));
  end;
  if IsUpperLimitViolated then begin
   JvUpperLimit:=(Vector3Dot(SliderAxisWorld,vA^)+Vector3Dot(R1PlusUCrossSliderAxis,wA^))-(Vector3Dot(SliderAxisWorld,vB^)+Vector3Dot(R2CrossSliderAxis,wB^));
   ImpulseUpper:=InverseMassMatrixLimit*(-JvUpperLimit);
   LambdaTemp:=AccumulatedImpulseUpperLimit;
   AccumulatedImpulseUpperLimit:=Max(0.0,AccumulatedImpulseUpperLimit+ImpulseUpper);
   ImpulseUpper:=-(AccumulatedImpulseUpperLimit-LambdaTemp);
   LinearImpulse:=Vector3ScalarMul(SliderAxisWorld,ImpulseUpper);
   AngularImpulseA:=Vector3ScalarMul(R1PlusUCrossSliderAxis,ImpulseUpper);
   AngularImpulseB:=Vector3ScalarMul(R2CrossSliderAxis,ImpulseUpper);
   Vector3DirectSub(vA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
   Vector3DirectSub(wA^,Vector3TermMatrixMul(AngularImpulseA,WorldInverseInertiaTensors[0]));
   Vector3DirectAdd(vB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
   Vector3DirectAdd(wB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]));
  end;
 end;

 (**** Motor ****)

 if MotorState then begin
  JvMotor:=Vector3Dot(SliderAxisWorld,vA^)-Vector3Dot(SliderAxisWorld,vB^);
  ImpulseMotor:=InverseMassMatrixMotor*(-JvMotor);
  LambdaTemp:=AccumulatedImpulseMotor;
  MaximalMotorImpulse:=MaximalMotorForce*TimeStep.DeltaTime;
  AccumulatedImpulseMotor:=Min(Max(AccumulatedImpulseMotor+ImpulseMotor,-MaximalMotorImpulse),MaximalMotorImpulse);
  ImpulseMotor:=-(AccumulatedImpulseMotor-LambdaTemp);
  LinearImpulse:=Vector3ScalarMul(SliderAxisWorld,ImpulseMotor);
  Vector3DirectSub(wA^,Vector3TermMatrixMul(LinearImpulse,WorldInverseInertiaTensors[0]));
  Vector3DirectAdd(wB^,Vector3TermMatrixMul(LinearImpulse,WorldInverseInertiaTensors[1]));
 end;

end;

function TKraftConstraintJointSlider.SolvePositionConstraint(const Island:TKraftIsland;const TimeStep:TKraftTimeStep):boolean;
var cA,cB:PKraftVector3;
    qA,qB:PKraftQuaternion;
    rA,rB,u,R1PlusU,I1R1PlusUCrossN1,I1R1PlusUCrossN2,I2R2CrossN1,I2R2CrossN2,
    LinearImpulse,AngularImpulseA,AngularImpulseB,RotationError,RotationImpulse:TKraftVector3;
    TranslationError,TranslationImpulse:TKraftVector2;
    uDotSliderAxis,InverseMassOfBodies,LowerLimitError,UpperLimitError,ImpulseLower,ImpulseUpper:TKraftScalar;
    TranslationKMatrix:TKraftMatrix2x2;
    CurrentOrientationDifference,qError:TKraftQuaternion;
begin

 cA:=@SolverPositions[0]^.Position;
 qA:=@SolverPositions[0]^.Orientation;

 cB:=@SolverPositions[1]^.Position;
 qB:=@SolverPositions[1]^.Orientation;

 rA:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),qA^);
 rB:=Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),qB^);

 u:=Vector3Sub(Vector3Add(cB^,rB),Vector3Add(cA^,rA));

 SliderAxisWorld:=Vector3NormEx(Vector3TermQuaternionRotate(SliderAxisBodyA,qA^));

 N1:=Vector3GetOneUnitOrthogonalVector(SliderAxisWorld);
 N2:=Vector3Cross(SliderAxisWorld,N1);

 uDotSliderAxis:=Vector3Dot(u,SliderAxisWorld);

 LowerLimitError:=uDotSliderAxis-LowerLimit;
 UpperLimitError:=UpperLimit-uDotSliderAxis;
 IsLowerLimitViolated:=LowerLimitError<=0.0;
 IsUpperLimitViolated:=UpperLimitError<=0.0;

 R2CrossN1:=Vector3Cross(RelativePositions[1],N1);
 R2CrossN2:=Vector3Cross(RelativePositions[1],N2);
 R2CrossSliderAxis:=Vector3Cross(RelativePositions[1],SliderAxisWorld);
 R1PlusU:=Vector3Cross(RelativePositions[0],u);
 R1PlusUCrossN1:=Vector3Cross(R1PlusU,N1);
 R1PlusUCrossN2:=Vector3Cross(R1PlusU,N2);
 R1PlusUCrossSliderAxis:=Vector3Cross(R1PlusU,SliderAxisWorld);

 (**** Translation ****)

 InverseMassOfBodies:=RigidBodies[0].InverseMass+RigidBodies[1].InverseMass;

 I1R1PlusUCrossN1:=Vector3TermMatrixMul(R1PlusUCrossN1,WorldInverseInertiaTensors[0]);
 I1R1PlusUCrossN2:=Vector3TermMatrixMul(R1PlusUCrossN2,WorldInverseInertiaTensors[0]);
 I2R2CrossN1:=Vector3TermMatrixMul(R2CrossN1,WorldInverseInertiaTensors[1]);
 I2R2CrossN2:=Vector3TermMatrixMul(R2CrossN2,WorldInverseInertiaTensors[1]);
 TranslationKMatrix[0,0]:=InverseMassOfBodies+Vector3Dot(R1PlusUCrossN1,I1R1PlusUCrossN1)+Vector3Dot(R2CrossN1,I2R2CrossN1);
 TranslationKMatrix[0,1]:=Vector3Dot(R1PlusUCrossN1,I1R1PlusUCrossN2)+Vector3Dot(R2CrossN1,I2R2CrossN2);
 TranslationKMatrix[1,0]:=Vector3Dot(R1PlusUCrossN2,I1R1PlusUCrossN1)+Vector3Dot(R2CrossN2,I2R2CrossN1);
 TranslationKMatrix[1,1]:=InverseMassOfBodies+Vector3Dot(R1PlusUCrossN2,I1R1PlusUCrossN2)+Vector3Dot(R2CrossN2,I2R2CrossN2);
 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  Matrix2x2Inverse(InverseMassMatrixTranslationConstraint,TranslationKMatrix);
 end else begin
  InverseMassMatrixRotationConstraint:=Matrix3x3Null;
 end;

 TranslationError.x:=Vector3Dot(u,N1);
 TranslationError.y:=Vector3Dot(u,N2);

 TranslationImpulse.x:=-((TranslationError.x*InverseMassMatrixTranslationConstraint[0,0])+(TranslationError.y*InverseMassMatrixTranslationConstraint[0,1]));
 TranslationImpulse.y:=-((TranslationError.x*InverseMassMatrixTranslationConstraint[1,0])+(TranslationError.y*InverseMassMatrixTranslationConstraint[1,1]));

 LinearImpulse:=Vector3Add(Vector3ScalarMul(N1,TranslationImpulse.x),
                           Vector3ScalarMul(N2,TranslationImpulse.y));

 AngularImpulseA:=Vector3Add(Vector3ScalarMul(R1PlusUCrossN1,TranslationImpulse.x),
                             Vector3ScalarMul(R1PlusUCrossN2,TranslationImpulse.y));

 AngularImpulseB:=Vector3Add(Vector3ScalarMul(R2CrossN1,TranslationImpulse.x),
                             Vector3ScalarMul(R2CrossN2,TranslationImpulse.y));

 result:=Vector2Length(TranslationError)<Physics.LinearSlop;

 Vector3DirectSub(cA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(AngularImpulseA),WorldInverseInertiaTensors[0]),1.0);

 Vector3DirectAdd(cB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]),1.0);

 (**** Rotation ****)

 if (RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic) then begin
  InverseMassMatrixRotationConstraint:=Matrix3x3TermInverse(Matrix3x3TermAdd(WorldInverseInertiaTensors[0],WorldInverseInertiaTensors[1]));
 end else begin
  InverseMassMatrixRotationConstraint:=Matrix3x3Null;
 end;

 CurrentOrientationDifference:=QuaternionTermNormalize(QuaternionMul(qB^,QuaternionInverse(qA^)));
 qError:=QuaternionMul(CurrentOrientationDifference,InverseInitialOrientationDifference);
 RotationError.x:=qError.x*2.0;
 RotationError.y:=qError.y*2.0;
 RotationError.z:=qError.z*2.0;

 RotationImpulse:=Vector3TermMatrixMul(Vector3Neg(RotationError),InverseMassMatrixRotationConstraint);

 result:=result and (Vector3Length(RotationError)<Physics.AngularSlop);

 QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(RotationImpulse),WorldInverseInertiaTensors[0]),1.0);

 QuaternionDirectSpin(qB^,Vector3TermMatrixMul(RotationImpulse,WorldInverseInertiaTensors[1]),1.0);

 (**** Limits ****)

 if LimitState then begin
  if IsLowerLimitViolated or IsUpperLimitViolated then begin
   InverseMassMatrixLimit:=InverseMassOfBodies+
                           Vector3Dot(R1PlusUCrossSliderAxis,Vector3TermMatrixMul(R1PlusUCrossSliderAxis,WorldInverseInertiaTensors[0]))+
                           Vector3Dot(R2CrossSliderAxis,Vector3TermMatrixMul(R2CrossSliderAxis,WorldInverseInertiaTensors[1]));
   if InverseMassMatrixLimit>0.0 then begin
    InverseMassMatrixLimit:=1.0/InverseMassMatrixLimit;
   end else begin
    InverseMassMatrixLimit:=0.0;
   end;
  end;
  if IsLowerLimitViolated then begin
   ImpulseLower:=InverseMassMatrixLimit*(-LowerLimitError);
   LinearImpulse:=Vector3ScalarMul(SliderAxisWorld,ImpulseLower);
   AngularImpulseA:=Vector3ScalarMul(R1PlusUCrossSliderAxis,ImpulseLower);
   AngularImpulseB:=Vector3ScalarMul(R2CrossSliderAxis,ImpulseLower);
   result:=result and (LowerLimitError<Physics.LinearSlop);
   Vector3DirectSub(cA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
   QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(AngularImpulseA),WorldInverseInertiaTensors[0]),1.0);
   Vector3DirectAdd(cB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
   QuaternionDirectSpin(qB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]),1.0);
  end;
  if IsUpperLimitViolated then begin
   ImpulseUpper:=-(InverseMassMatrixLimit*(-UpperLimitError));
   LinearImpulse:=Vector3ScalarMul(SliderAxisWorld,ImpulseUpper);
   AngularImpulseA:=Vector3ScalarMul(R1PlusUCrossSliderAxis,ImpulseUpper);
   AngularImpulseB:=Vector3ScalarMul(R2CrossSliderAxis,ImpulseUpper);
   result:=result and (UpperLimitError<Physics.LinearSlop);
   Vector3DirectSub(cA^,Vector3ScalarMul(LinearImpulse,InverseMasses[0]));
   QuaternionDirectSpin(qA^,Vector3TermMatrixMul(Vector3Neg(AngularImpulseA),WorldInverseInertiaTensors[0]),1.0);
   Vector3DirectAdd(cB^,Vector3ScalarMul(LinearImpulse,InverseMasses[1]));
   QuaternionDirectSpin(qB^,Vector3TermMatrixMul(AngularImpulseB,WorldInverseInertiaTensors[1]),1.0);
  end;
 end;

end;

function TKraftConstraintJointSlider.GetAnchorA:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[0],RigidBodies[0].WorldTransform);
end;

function TKraftConstraintJointSlider.GetAnchorB:TKraftVector3;
begin
 result:=Vector3TermMatrixMul(LocalAnchors[1],RigidBodies[1].WorldTransform);
end;

function TKraftConstraintJointSlider.GetReactionForce(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(Vector3Add(Vector3ScalarMul(N1,AccumulatedImpulseTranslation.x),
                                             Vector3ScalarMul(N2,AccumulatedImpulseTranslation.y)),InverseDeltaTime);
end;

function TKraftConstraintJointSlider.GetReactionTorque(const InverseDeltaTime:TKraftScalar):TKraftVector3;
begin
 result:=Vector3ScalarMul(AccumulatedImpulseRotation,InverseDeltaTime);
end;

function TKraftConstraintJointSlider.IsLimitEnabled:boolean;
begin
 result:=LimitState;
end;

function TKraftConstraintJointSlider.IsMotorEnabled:boolean;
begin
 result:=MotorState;
end;

function TKraftConstraintJointSlider.GetMinimumTranslationLimit:TKraftScalar;
begin
 result:=LowerLimit;
end;

function TKraftConstraintJointSlider.GetMaximumTranslationLimit:TKraftScalar;
begin
 result:=UpperLimit;
end;

function TKraftConstraintJointSlider.GetMotorSpeed:TKraftScalar;
begin
 result:=MotorSpeed;
end;

function TKraftConstraintJointSlider.GetMaximalMotorForce:TKraftScalar;
begin
 result:=MaximalMotorForce;
end;

function TKraftConstraintJointSlider.GetMotorForce(const DeltaTime:TKraftScalar):TKraftScalar;
begin
 result:=AccumulatedImpulseMotor/DeltaTime;
end;

function TKraftConstraintJointSlider.GetTranslation:TKraftScalar;
begin
 result:=Vector3Dot(Vector3Sub(Vector3Add(SolverPositions[1]^.Position,Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[1],LocalCenters[1]),SolverPositions[1]^.Orientation)),
                                       Vector3Add(SolverPositions[0]^.Position,Vector3TermQuaternionRotate(Vector3Sub(LocalAnchors[0],LocalCenters[0]),SolverPositions[0]^.Orientation))),
                        Vector3TermQuaternionRotate(SliderAxisBodyA,SolverPositions[0]^.Orientation));
end;

procedure TKraftConstraintJointSlider.ResetLimits;
begin
 AccumulatedImpulseLowerLimit:=0.0;
 AccumulatedImpulseUpperLimit:=0.0;
 RigidBodies[0].SetToAwake;
 RigidBodies[1].SetToAwake;
end;

procedure TKraftConstraintJointSlider.EnableLimit(const ALimitEnabled:boolean);
begin
 if LimitState<>ALimitEnabled then begin
  LimitState:=ALimitEnabled;
  ResetLimits;
 end;
end;

procedure TKraftConstraintJointSlider.EnableMotor(const AMotorEnabled:boolean);
begin
 if MotorState<>AMotorEnabled then begin
  MotorState:=AMotorEnabled;
  AccumulatedImpulseMotor:=0.0;
  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;
 end;
end;

procedure TKraftConstraintJointSlider.SetMinimumTranslationLimit(const AMinimumTranslationLimit:TKraftScalar);
begin
 if LowerLimit<>AMinimumTranslationLimit then begin
  LowerLimit:=AMinimumTranslationLimit;
  ResetLimits;
 end;
end;

procedure TKraftConstraintJointSlider.SetMaximumTranslationLimit(const AMaximumTranslationLimit:TKraftScalar);
begin
 if UpperLimit<>AMaximumTranslationLimit then begin
  UpperLimit:=AMaximumTranslationLimit;
  ResetLimits;
 end;
end;

procedure TKraftConstraintJointSlider.SetMotorSpeed(const AMotorSpeed:TKraftScalar);
begin
 if MotorSpeed<>AMotorSpeed then begin
  MotorSpeed:=AMotorSpeed;
  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;
 end;
end;

procedure TKraftConstraintJointSlider.SetMaximalMotorForce(const AMaximalMotorForce:TKraftScalar);
begin
 if MaximalMotorForce<>AMaximalMotorForce then begin
  MaximalMotorForce:=AMaximalMotorForce;
  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;
 end;
end;

constructor TKraftSolver.Create(const APhysics:TKraft;const AIsland:TKraftIsland);
begin
 inherited Create;

 Physics:=APhysics;

 Island:=AIsland;

 Velocities:=nil;
 SetLength(Velocities,64);
 CountVelocities:=0;

 Positions:=nil;
 SetLength(Positions,64);
 CountPositions:=0;

 VelocityStates:=nil;
 SetLength(VelocityStates,64);
 CountVelocityStates:=0;

 PositionStates:=nil;
 SetLength(PositionStates,64);
 CountPositionStates:=0;

 CountContacts:=0;

end;

destructor TKraftSolver.Destroy;
begin
 SetLength(Velocities,0);
 SetLength(Positions,0);
 SetLength(VelocityStates,0);
 SetLength(PositionStates,0);
 inherited Destroy;
end;

procedure TKraftSolver.Initialize(const TimeStep:TKraftTimeStep);
begin
 DeltaTime:=TimeStep.DeltaTime;
 DeltaTimeRatio:=TimeStep.DeltaTimeRatio;
 EnableFriction:=Physics.EnableFriction;
end;

procedure TKraftSolver.Store;
var ContactPairIndex,ContactIndex:longint;
    VelocityState:PKraftSolverVelocityState;
    PositionState:PKraftSolverPositionState;
    ContactPair:PKraftContactPair;
    Contact:PKraftContact;
    ContactPoint:PKraftSolverVelocityStateContactPoint;
begin

 if Island.CountRigidBodies>length(Velocities) then begin
  SetLength(Velocities,Island.CountRigidBodies*2);
 end;
 CountVelocities:=Island.CountRigidBodies;

 if Island.CountRigidBodies>length(Positions) then begin
  SetLength(Positions,Island.CountRigidBodies*2);
 end;
 CountPositions:=Island.CountRigidBodies;

 CountContacts:=Island.CountContactPairs;

 if CountContacts>length(VelocityStates) then begin
  SetLength(VelocityStates,CountContacts*2);
 end;
 CountVelocityStates:=CountContacts;

 if CountContacts>length(PositionStates) then begin
  SetLength(PositionStates,CountContacts*2);
 end;
 CountPositionStates:=CountContacts;

 for ContactPairIndex:=0 to CountContacts-1 do begin

  ContactPair:=Island.ContactPairs[ContactPairIndex];

  VelocityState:=@VelocityStates[ContactPairIndex];
  VelocityState^.Centers[0]:=ContactPair^.RigidBodies[0].Sweep.c0;
  VelocityState^.Centers[1]:=ContactPair^.RigidBodies[1].Sweep.c0;
  VelocityState^.WorldInverseInertiaTensors[0]:=ContactPair^.RigidBodies[0].WorldInverseInertiaTensor;
  VelocityState^.WorldInverseInertiaTensors[1]:=ContactPair^.RigidBodies[1].WorldInverseInertiaTensor;
  VelocityState^.NormalMass:=0.0;
  VelocityState^.TangentMass[0]:=0.0;
  VelocityState^.TangentMass[1]:=0.0;
  VelocityState^.InverseMasses[0]:=ContactPair^.RigidBodies[0].InverseMass;
  VelocityState^.InverseMasses[1]:=ContactPair^.RigidBodies[1].InverseMass;
  VelocityState^.Restitution:=ContactPair^.Restitution;
  VelocityState^.Friction:=ContactPair^.Friction;
  VelocityState^.Indices[0]:=ContactPair^.RigidBodies[0].IslandIndices[Island.IslandIndex];
  VelocityState^.Indices[1]:=ContactPair^.RigidBodies[1].IslandIndices[Island.IslandIndex];
  VelocityState^.CountPoints:=ContactPair^.Manifold.CountContacts;

  PositionState:=@PositionStates[ContactPairIndex];
  PositionState^.LocalNormal:=ContactPair^.Manifold.LocalNormal;
  PositionState^.LocalCenters[0]:=ContactPair^.RigidBodies[0].Sweep.LocalCenter;
  PositionState^.LocalCenters[1]:=ContactPair^.RigidBodies[1].Sweep.LocalCenter;
  PositionState^.WorldInverseInertiaTensors[0]:=ContactPair^.RigidBodies[0].WorldInverseInertiaTensor;
  PositionState^.WorldInverseInertiaTensors[1]:=ContactPair^.RigidBodies[1].WorldInverseInertiaTensor;
  PositionState^.InverseMasses[0]:=ContactPair^.RigidBodies[0].InverseMass;
  PositionState^.InverseMasses[1]:=ContactPair^.RigidBodies[1].InverseMass;
  PositionState^.Indices[0]:=ContactPair^.RigidBodies[0].IslandIndices[Island.IslandIndex];
  PositionState^.Indices[1]:=ContactPair^.RigidBodies[1].IslandIndices[Island.IslandIndex];
  PositionState^.CountPoints:=ContactPair^.Manifold.CountContacts;

  for ContactIndex:=0 to ContactPair^.Manifold.CountContacts-1 do begin

   Contact:=@ContactPair^.Manifold.Contacts[ContactIndex];

   ContactPoint:=@VelocityState^.Points[ContactIndex];

   ContactPoint^.RelativePositions[0]:=Vector3Origin;
   ContactPoint^.RelativePositions[1]:=Vector3Origin;
   if Physics.WarmStarting then begin
    ContactPoint^.NormalImpulse:=Contact^.NormalImpulse*DeltaTimeRatio;
    ContactPoint^.TangentImpulse[0]:=Contact^.TangentImpulse[0]*DeltaTimeRatio;
    ContactPoint^.TangentImpulse[1]:=Contact^.TangentImpulse[1]*DeltaTimeRatio;
   end else begin
    ContactPoint^.NormalImpulse:=0.0;
    ContactPoint^.TangentImpulse[0]:=0.0;
    ContactPoint^.TangentImpulse[1]:=0.0;
   end;
   ContactPoint^.Bias:=0.0;
   ContactPoint^.NormalMass:=0.0;
   ContactPoint^.TangentMass[0]:=0.0;
   ContactPoint^.TangentMass[1]:=0.0;

   PositionState^.LocalPoints[ContactIndex]:=Contact^.LocalPoints[ContactIndex];

  end;

 end;

end;

procedure TKraftSolver.InitializeConstraints;
var ContactPairIndex,ContactIndex,TangentIndex,IndexA,IndexB:longint;
    VelocityState:PKraftSolverVelocityState;
    PositionState:PKraftSolverPositionState;
    ContactPoint:PKraftSolverVelocityStateContactPoint;
    SolverContact:PKraftSolverContact;
    iA,iB:PKraftMatrix3x3;
    mA,mB,NormalMass,TangentMass,dv:TKraftScalar;
    LocalCenterA,LocalCenterB,cA,vA,wA,rnA,rtA,cB,vB,wB,rnB,rtB,P,Temp:TKraftVector3;
    t:array[0..1] of TKraftVector3;
    qA,qB:TKraftQuaternion;
    tA,tB:TKraftMatrix4x4;
    SolverContactManifold:TKraftSolverContactManifold;
begin
 for ContactPairIndex:=0 to CountContacts-1 do begin

  VelocityState:=@VelocityStates[ContactPairIndex];

  PositionState:=@PositionStates[ContactPairIndex];

  IndexA:=VelocityState^.Indices[0];
  IndexB:=VelocityState^.Indices[1];

  iA:=@VelocityState^.WorldInverseInertiaTensors[0];
  iB:=@VelocityState^.WorldInverseInertiaTensors[1];

  mA:=VelocityState^.InverseMasses[0];
  mB:=VelocityState^.InverseMasses[1];

  LocalCenterA:=PositionState^.LocalCenters[0];
  LocalCenterB:=PositionState^.LocalCenters[1];

  cA:=Positions[IndexA].Position;
  qA:=Positions[IndexA].Orientation;
  tA:=QuaternionToMatrix4x4(qA);
  Temp:=Vector3Sub(cA,Vector3TermMatrixMulBasis(LocalCenterA,tA));
  PKraftVector3(pointer(@tA[3,0]))^.xyz:=PKraftVector3(pointer(@Temp))^.xyz;

  cB:=Positions[IndexB].Position;
  qB:=Positions[IndexB].Orientation;
  tB:=QuaternionToMatrix4x4(qB);
  Temp:=Vector3Sub(cB,Vector3TermMatrixMulBasis(LocalCenterB,tB));
  PKraftVector3(pointer(@tB[3,0]))^.xyz:=PKraftVector3(pointer(@Temp))^.xyz;

  vA:=Velocities[IndexA].LinearVelocity;
  wA:=Velocities[IndexA].AngularVelocity;

  vB:=Velocities[IndexB].LinearVelocity;
  wB:=Velocities[IndexB].AngularVelocity;

  Island.ContactPairs[ContactPairIndex]^.GetSolverContactManifold(SolverContactManifold,tA,tB,false);

  VelocityState^.CountPoints:=SolverContactManifold.CountContacts;

  VelocityState^.Normal:=SolverContactManifold.Normal;

  ComputeBasis(VelocityState^.Normal,t[0],t[1]);

  for ContactIndex:=0 to SolverContactManifold.CountContacts-1 do begin

   ContactPoint:=@VelocityState^.Points[ContactIndex];

   SolverContact:=@SolverContactManifold.Contacts[ContactIndex];

   P:=SolverContact^.Point;
   ContactPoint^.RelativePositions[0]:=Vector3Sub(P,cA);
   ContactPoint^.RelativePositions[1]:=Vector3Sub(P,cB);

   rnA:=Vector3Cross(ContactPoint^.RelativePositions[0],VelocityState^.Normal);
   rnB:=Vector3Cross(ContactPoint^.RelativePositions[1],VelocityState^.Normal);

   NormalMass:=mA+mB+Vector3Dot(rnA,Vector3TermMatrixMul(rnA,iA^))+Vector3Dot(rnB,Vector3TermMatrixMul(rnB,iB^));
                     
   if NormalMass>0.0 then begin
{   if NormalMass<=EPSILON then begin
     writeln('n ',ContactPoint^.NormalMass:1:8);
    end;{}
    ContactPoint^.NormalMass:=1.0/NormalMass;
   end else begin
    ContactPoint^.NormalMass:=0.0;
   end;

   for TangentIndex:=0 to 1 do begin

    rtA:=Vector3Cross(t[TangentIndex],ContactPoint^.RelativePositions[0]);
    rtB:=Vector3Cross(t[TangentIndex],ContactPoint^.RelativePositions[1]);

    TangentMass:=mA+mB+Vector3Dot(rtA,Vector3TermMatrixMul(rtA,iA^))+Vector3Dot(rtB,Vector3TermMatrixMul(rtB,iB^));

    if TangentMass>0.0 then begin
{    if TangentMass>1000.0 then begin
      writeln('t ',TangentMass:1:8);
     end;
     writeln('t ',TangentMass:1:8);{}
{    if TangentMass<=EPSILON then begin
      writeln('t ',TangentMass:1:8);
     end;{}
     ContactPoint^.TangentMass[TangentIndex]:=1.0/TangentMass;
    end else begin
     ContactPoint^.TangentMass[TangentIndex]:=0.0;
    end;

   end;

   dv:=Vector3Dot(Vector3Sub(Vector3Add(vB,
                                        Vector3Cross(wB,
                                                     ContactPoint^.RelativePositions[1])),
                             Vector3Add(vA,
                                        Vector3Cross(wA,
                                                     ContactPoint^.RelativePositions[0]))),
                  VelocityState^.Normal);
   if dv<-1.0 then begin
    ContactPoint^.Bias:=-(VelocityState^.Restitution*dv);
   end else begin
    ContactPoint^.Bias:=0.0;
   end;

  end;

 end;

end;

procedure TKraftSolver.WarmStart;
var ContactPairIndex,ContactIndex,IndexA,IndexB,CountPoints:longint;
    VelocityState:PKraftSolverVelocityState;
    ContactPoint:PKraftSolverVelocityStateContactPoint;
    iA,iB:PKraftMatrix3x3;
    mA,mB:TKraftScalar;
    Normal,t0,t1,vA,wA,vB,wB,P:TKraftVector3;
begin
 for ContactPairIndex:=0 to CountContacts-1 do begin

  VelocityState:=@VelocityStates[ContactPairIndex];
  IndexA:=VelocityState^.Indices[0];
  IndexB:=VelocityState^.Indices[1];
  iA:=@VelocityState^.WorldInverseInertiaTensors[0];
  iB:=@VelocityState^.WorldInverseInertiaTensors[1];
  mA:=VelocityState^.InverseMasses[0];
  mB:=VelocityState^.InverseMasses[1];
  CountPoints:=VelocityState^.CountPoints;
  Normal:=VelocityState^.Normal;
  ComputeBasis(Normal,t0,t1);

  vA:=Velocities[IndexA].LinearVelocity;
  wA:=Velocities[IndexA].AngularVelocity;
  vB:=Velocities[IndexB].LinearVelocity;
  wB:=Velocities[IndexB].AngularVelocity;

  for ContactIndex:=0 to CountPoints-1 do begin

   ContactPoint:=@VelocityState^.Points[ContactIndex];

   P:=Vector3Add(Vector3ScalarMul(Normal,ContactPoint^.NormalImpulse),Vector3Add(Vector3ScalarMul(t0,ContactPoint^.TangentImpulse[0]),Vector3ScalarMul(t1,ContactPoint^.TangentImpulse[1])));

   Vector3DirectSub(vA,Vector3ScalarMul(P,mA));
   Vector3DirectSub(wA,Vector3TermMatrixMul(Vector3Cross(ContactPoint^.RelativePositions[0],P),iA^));

   Vector3DirectAdd(vB,Vector3ScalarMul(P,mB));
   Vector3DirectAdd(wB,Vector3TermMatrixMul(Vector3Cross(ContactPoint^.RelativePositions[1],P),iB^));

  end;

  Velocities[IndexA].LinearVelocity:=vA;
  Velocities[IndexA].AngularVelocity:=wA;
  Velocities[IndexB].LinearVelocity:=vB;
  Velocities[IndexB].AngularVelocity:=wB;

 end;
end;

procedure TKraftSolver.SolveVelocityConstraints;
var ContactPairIndex,ContactIndex,TangentIndex,IndexA,IndexB,CountPoints:longint;
    VelocityState:PKraftSolverVelocityState;
    ContactPoint:PKraftSolverVelocityStateContactPoint;
    iA,iB:PKraftMatrix3x3;
    mA,mB,Friction,NormalImpulse,NormalMass,Bias,Lambda,MaxFriction,NewImpulse,vn:TKraftScalar;
    Normal,t0,t1,vA,wA,rA,vB,wB,rB,dv,P:TKraftVector3;
    Basis:TKraftMatrix3x3;
    TangentMass,TangentImpulse:array[0..1] of TKraftScalar;
    t:array[0..1] of TKraftVector3;
begin
 for ContactPairIndex:=0 to CountContacts-1 do begin

  VelocityState:=@VelocityStates[ContactPairIndex];
  IndexA:=VelocityState^.Indices[0];
  IndexB:=VelocityState^.Indices[1];
  iA:=@VelocityState^.WorldInverseInertiaTensors[0];
  iB:=@VelocityState^.WorldInverseInertiaTensors[1];
  mA:=VelocityState^.InverseMasses[0];
  mB:=VelocityState^.InverseMasses[1];
  CountPoints:=VelocityState^.CountPoints;
  Normal:=VelocityState^.Normal;
  Friction:=VelocityState^.Friction;
  ComputeBasis(Normal,t[0],t[1]);

  vA:=Velocities[IndexA].LinearVelocity;
  wA:=Velocities[IndexA].AngularVelocity;
  vB:=Velocities[IndexB].LinearVelocity;
  wB:=Velocities[IndexB].AngularVelocity;

  for ContactIndex:=0 to CountPoints-1 do begin

   ContactPoint:=@VelocityState^.Points[ContactIndex];

   rA:=ContactPoint^.RelativePositions[0];
   rB:=ContactPoint^.RelativePositions[1];
   NormalImpulse:=ContactPoint^.NormalImpulse;
   NormalMass:=ContactPoint^.NormalMass;
   Bias:=ContactPoint^.Bias;
   TangentMass[0]:=ContactPoint^.TangentMass[0];
   TangentMass[1]:=ContactPoint^.TangentMass[1];
   TangentImpulse[0]:=ContactPoint^.TangentImpulse[0];
   TangentImpulse[1]:=ContactPoint^.TangentImpulse[1];

   if EnableFriction then begin

    for TangentIndex:=0 to 1 do begin

     dv:=Vector3Sub(Vector3Add(vB,Vector3Cross(wB,rB)),Vector3Add(vA,Vector3Cross(wA,rA)));

     Lambda:=(-Vector3Dot(dv,t[TangentIndex]))*TangentMass[TangentIndex];

     MaxFriction:=Friction*NormalImpulse;

     NewImpulse:=Min(Max(TangentImpulse[TangentIndex]+Lambda,-MaxFriction),MaxFriction);

     Lambda:=NewImpulse-TangentImpulse[TangentIndex];
     ContactPoint^.TangentImpulse[TangentIndex]:=NewImpulse;

     P:=Vector3ScalarMul(t[TangentIndex],Lambda);

     Vector3DirectSub(vA,Vector3ScalarMul(P,mA));
     Vector3DirectSub(wA,Vector3TermMatrixMul(Vector3Cross(rA,P),iA^));

     Vector3DirectAdd(vB,Vector3ScalarMul(P,mB));
     Vector3DirectAdd(wB,Vector3TermMatrixMul(Vector3Cross(rB,P),iB^));

    end;

   end;

   dv:=Vector3Sub(Vector3Add(vB,Vector3Cross(wB,rB)),Vector3Add(vA,Vector3Cross(wA,rA)));

   vn:=Vector3Dot(dv,Normal);
   Lambda:=NormalMass*(Bias-vn);
   NewImpulse:=Max(0.0,NormalImpulse+Lambda);
   Lambda:=NewImpulse-NormalImpulse;
   ContactPoint^.NormalImpulse:=NewImpulse;

   P:=Vector3ScalarMul(Normal,Lambda);

   Vector3DirectSub(vA,Vector3ScalarMul(P,mA));
   Vector3DirectSub(wA,Vector3TermMatrixMul(Vector3Cross(rA,P),iA^));

   Vector3DirectAdd(vB,Vector3ScalarMul(P,mB));
   Vector3DirectAdd(wB,Vector3TermMatrixMul(Vector3Cross(rB,P),iB^));
  end;

  Velocities[IndexA].LinearVelocity:=vA;
  Velocities[IndexA].AngularVelocity:=wA;
  Velocities[IndexB].LinearVelocity:=vB;
  Velocities[IndexB].AngularVelocity:=wB;

 end;
end;

function TKraftSolver.SolvePositionConstraints:boolean;
var ContactPairIndex,ContactIndex,IndexA,IndexB:longint;
    PositionState:PKraftSolverPositionState;
    SolverContact:PKraftSolverContact;
    iA,iB:PKraftMatrix3x3;
    MinSeparation,mA,mB,Separation,C,K,Impulse:TKraftScalar;
    LocalCenterA,LocalCenterB,cA,cB,Normal,Point,rA,rB,rnA,rnB,P,Temp:TKraftVector3;
    qA,qB:TKraftQuaternion;
    tA,tB:TKraftMatrix4x4;
    SolverContactManifold:TKraftSolverContactManifold;
begin
 MinSeparation:=0.0;
 for ContactPairIndex:=0 to CountContacts-1 do begin

  PositionState:=@PositionStates[ContactPairIndex];

  IndexA:=PositionState^.Indices[0];
  IndexB:=PositionState^.Indices[1];

  iA:=@PositionState^.WorldInverseInertiaTensors[0];
  iB:=@PositionState^.WorldInverseInertiaTensors[1];

  mA:=PositionState^.InverseMasses[0];
  mB:=PositionState^.InverseMasses[1];

  LocalCenterA:=PositionState^.LocalCenters[0];
  LocalCenterB:=PositionState^.LocalCenters[1];

  cA:=Positions[IndexA].Position;
  qA:=Positions[IndexA].Orientation;
  tA:=QuaternionToMatrix4x4(qA);
  Temp:=Vector3Sub(cA,Vector3TermMatrixMulBasis(LocalCenterA,tA));
  PKraftVector3(pointer(@tA[3,0]))^.xyz:=PKraftVector3(pointer(@Temp))^.xyz;

  cB:=Positions[IndexB].Position;
  qB:=Positions[IndexB].Orientation;
  tB:=QuaternionToMatrix4x4(qB);
  Temp:=Vector3Sub(cB,Vector3TermMatrixMulBasis(LocalCenterB,tB));
  PKraftVector3(pointer(@tB[3,0]))^.xyz:=PKraftVector3(pointer(@Temp))^.xyz;

  Island.ContactPairs[ContactPairIndex]^.GetSolverContactManifold(SolverContactManifold,tA,tB,true);

  Normal:=SolverContactManifold.Normal;

  for ContactIndex:=0 to SolverContactManifold.CountContacts-1 do begin

   SolverContact:=@SolverContactManifold.Contacts[ContactIndex];

   Point:=SolverContact^.Point;
   Separation:=SolverContact^.Separation;

   rA:=Vector3Sub(Point,cA);
   rB:=Vector3Sub(Point,cB);

   if MinSeparation>Separation then begin
    MinSeparation:=Separation;
   end;

   C:=Min(Max(Physics.Baumgarte*(Separation+Physics.LinearSlop),-Physics.MaximalLinearCorrection),0.0);

   rnA:=Vector3Cross(rA,Normal);
   rnB:=Vector3Cross(rB,Normal);

   K:=mA+mB+Vector3Dot(rnA,Vector3TermMatrixMul(rnA,iA^))+Vector3Dot(rnB,Vector3TermMatrixMul(rnB,iB^));

   if K>0.0 then begin
    Impulse:=-(C/K);   
   end else begin
    Impulse:=0.0;
   end;

   P:=Vector3ScalarMul(Normal,Impulse);

   Vector3DirectSub(cA,Vector3ScalarMul(P,mA));
   QuaternionDirectSpin(qA,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(P)),iA^),1.0);

   Vector3DirectAdd(cB,Vector3ScalarMul(P,mB));
   QuaternionDirectSpin(qB,Vector3TermMatrixMul(Vector3Cross(rB,P),iB^),1.0);

  end;

  Positions[IndexA].Position:=cA;
  Positions[IndexA].Orientation:=qA;

  Positions[IndexB].Position:=cB;
  Positions[IndexB].Orientation:=qB;

 end;

 result:=MinSeparation>=((-3.0)*Physics.LinearSlop);
end;

function TKraftSolver.SolveTimeOfImpactConstraints(IndexA,IndexB:longint):boolean;
var ContactPairIndex,ContactIndex,CurrentIndexA,CurrentIndexB:longint;
    PositionState:PKraftSolverPositionState;
    SolverContact:PKraftSolverContact;
    iA,iB:PKraftMatrix3x3;
    MinSeparation,mA,mB,Separation,C,K,Impulse:TKraftScalar;
    LocalCenterA,LocalCenterB,cA,cB,Normal,Point,rA,rB,rnA,rnB,P,Temp:TKraftVector3;
    qA,qB:TKraftQuaternion;
    tA,tB:TKraftMatrix4x4;
    SolverContactManifold:TKraftSolverContactManifold;
begin

 MinSeparation:=0.0;

 for ContactPairIndex:=0 to CountContacts-1 do begin

  PositionState:=@PositionStates[ContactPairIndex];

  CurrentIndexA:=PositionState^.Indices[0];
  CurrentIndexB:=PositionState^.Indices[1];

  LocalCenterA:=PositionState^.LocalCenters[0];
  LocalCenterB:=PositionState^.LocalCenters[1];

  if (CurrentIndexA=IndexA) or (CurrentIndexA=IndexB) then begin
   iA:=@PositionState^.WorldInverseInertiaTensors[0];
   mA:=PositionState^.InverseMasses[0];
  end else begin
   mA:=0.0;
   iA:=@Matrix3x3Null;
  end;

  if (CurrentIndexB=IndexA) or (CurrentIndexB=IndexB) then begin
   iB:=@PositionState^.WorldInverseInertiaTensors[1];
   mB:=PositionState^.InverseMasses[1];
  end else begin
   mB:=0.0;
   iB:=@Matrix3x3Null;
  end;

  cA:=Positions[IndexA].Position;
  qA:=Positions[IndexA].Orientation;
  tA:=QuaternionToMatrix4x4(qA);
  Temp:=Vector3Sub(cA,Vector3TermMatrixMulBasis(LocalCenterA,tA));
  PKraftVector3(pointer(@tA[3,0]))^.xyz:=PKraftVector3(pointer(@Temp))^.xyz;

  cB:=Positions[IndexB].Position;
  qB:=Positions[IndexB].Orientation;
  tB:=QuaternionToMatrix4x4(qB);
  Temp:=Vector3Sub(cB,Vector3TermMatrixMulBasis(LocalCenterB,tB));
  PKraftVector3(pointer(@tB[3,0]))^.xyz:=PKraftVector3(pointer(@Temp))^.xyz;

  Island.ContactPairs[ContactPairIndex]^.GetSolverContactManifold(SolverContactManifold,tA,tB,true);

  Normal:=SolverContactManifold.Normal;

  for ContactIndex:=0 to SolverContactManifold.CountContacts-1 do begin

   SolverContact:=@SolverContactManifold.Contacts[ContactIndex];

   Point:=SolverContact^.Point;
   Separation:=SolverContact^.Separation;

   rA:=Vector3Sub(Point,cA);
   rB:=Vector3Sub(Point,cB);

   if MinSeparation>Separation then begin
    MinSeparation:=Separation;
   end;

   C:=Min(Max(Physics.TimeOfImpactBaumgarte*(Separation+Physics.LinearSlop),-Physics.MaximalLinearCorrection),0.0);

   rnA:=Vector3Cross(rA,Normal);
   rnB:=Vector3Cross(rB,Normal);

   K:=mA+mB+Vector3Dot(rnA,Vector3TermMatrixMul(rnA,iA^))+Vector3Dot(rnB,Vector3TermMatrixMul(rnB,iB^));

   if K>0.0 then begin
    Impulse:=-(C/K);
   end else begin
    Impulse:=0.0;
   end;

   P:=Vector3ScalarMul(Normal,Impulse);

   Vector3DirectSub(cA,Vector3ScalarMul(P,mA));
   QuaternionDirectSpin(qA,Vector3TermMatrixMul(Vector3Cross(rA,Vector3Neg(P)),iA^),1.0);

   Vector3DirectAdd(cB,Vector3ScalarMul(P,mB));
   QuaternionDirectSpin(qB,Vector3TermMatrixMul(Vector3Cross(rB,P),iB^),1.0);

  end;

  Positions[IndexA].Position:=cA;
  Positions[IndexA].Orientation:=qA;

  Positions[IndexB].Position:=cB;
  Positions[IndexB].Orientation:=qB;

 end;

 result:=MinSeparation>=((-1.5)*Physics.LinearSlop);
end;

procedure TKraftSolver.StoreImpulses;
var i,j:longint;
    VelocityState:PKraftSolverVelocityState;
    ContactPair:PKraftContactPair;
    Contact:PKraftContact;
    ContactPoint:PKraftSolverVelocityStateContactPoint;
begin
 for i:=0 to CountContacts-1 do begin
  VelocityState:=@VelocityStates[i];
  ContactPair:=Island.ContactPairs[i];
  for j:=0 to VelocityState^.CountPoints-1 do begin
   Contact:=@ContactPair^.Manifold.Contacts[j];
   ContactPoint:=@VelocityState^.Points[j];
   Contact^.NormalImpulse:=ContactPoint^.NormalImpulse;
   Contact^.TangentImpulse[0]:=ContactPoint^.TangentImpulse[0];
   Contact^.TangentImpulse[1]:=ContactPoint^.TangentImpulse[1];
  end;
 end;
end;

constructor TKraftIsland.Create(const APhysics:TKraft;const AIndex:longint);
begin
 inherited Create;

 Physics:=APhysics;

 IslandIndex:=AIndex;

 RigidBodies:=nil;
 SetLength(RigidBodies,64);
 CountRigidBodies:=0;

 Constraints:=nil;
 SetLength(Constraints,64);
 CountConstraints:=0;

 ContactPairs:=nil;
 SetLength(ContactPairs,64);
 CountContactPairs:=0;

 StaticContactPairs:=nil;
 SetLength(StaticContactPairs,64);
 CountStaticContactPairs:=0;

 Solver:=TKraftSolver.Create(Physics,self);

end;

destructor TKraftIsland.Destroy;
begin
 SetLength(RigidBodies,0);
 SetLength(Constraints,0);
 SetLength(ContactPairs,0);
 SetLength(StaticContactPairs,0);
 Solver.Free;
 inherited Destroy;
end;

procedure TKraftIsland.Clear;
begin
 CountRigidBodies:=0;
 CountConstraints:=0;
 CountContactPairs:=0;
 CountStaticContactPairs:=0;
end;

function TKraftIsland.AddRigidBody(RigidBody:TKraftRigidBody):longint;
begin
 RigidBody.Island:=self;
 if (CountRigidBodies+1)>length(RigidBodies) then begin
  SetLength(RigidBodies,(CountRigidBodies+1)*2);
 end;
 RigidBodies[CountRigidBodies]:=RigidBody;
 if IslandIndex>=length(RigidBody.IslandIndices) then begin
  SetLength(RigidBody.IslandIndices,(IslandIndex+1)*2);
 end;
 RigidBody.IslandIndices[IslandIndex]:=CountRigidBodies;
 result:=CountRigidBodies;
 inc(CountRigidBodies);
end;

procedure TKraftIsland.AddConstraint(Constraint:TKraftConstraint);
begin
 if (CountConstraints+1)>length(Constraints) then begin
  SetLength(Constraints,(CountConstraints+1)*2);
 end;
 Constraints[CountConstraints]:=Constraint;
 inc(CountConstraints);
end;

procedure TKraftIsland.AddContactPair(ContactPair:PKraftContactPair);
begin
 ContactPair^.Island:=self;
 if (assigned(ContactPair^.RigidBodies[0]) and (ContactPair^.RigidBodies[0].RigidBodyType=krbtDynamic)) and
    (assigned(ContactPair^.RigidBodies[1]) and (ContactPair^.RigidBodies[1].RigidBodyType=krbtDynamic)) then begin
  // Dynamic vs dynamic (solving before dynamic vs static in a solver iteration)
  if (CountContactPairs+1)>length(ContactPairs) then begin
   SetLength(ContactPairs,(CountContactPairs+1)*2);
  end;
  ContactPairs[CountContactPairs]:=ContactPair;
  inc(CountContactPairs);
 end else begin
  // Dynamic vs static (solving after dynamic vs dynamic in a solver iteration)
  if (CountStaticContactPairs+1)>length(StaticContactPairs) then begin
   SetLength(StaticContactPairs,(CountStaticContactPairs+1)*2);
  end;
  StaticContactPairs[CountStaticContactPairs]:=ContactPair;
  inc(CountStaticContactPairs);
 end;
end;

procedure TKraftIsland.MergeContactPairs;
var NewCountContactPairs:longint;
begin
 NewCountContactPairs:=CountContactPairs+CountStaticContactPairs;
 if length(ContactPairs)<NewCountContactPairs then begin
  SetLength(ContactPairs,NewCountContactPairs*2);
 end;
 if CountStaticContactPairs>0 then begin
  Move(StaticContactPairs[0],ContactPairs[CountContactPairs],CountStaticContactPairs*SizeOf(PKraftContactPair));
  inc(CountContactPairs,CountStaticContactPairs);
 end;
end;

procedure TKraftIsland.Solve(const TimeStep:TKraftTimeStep);
var Iteration,i:longint;
    RigidBody:TKraftRigidBody;
    Constraint:TKraftConstraint;
    MinSleepTime,s:TKraftScalar;
    First,OK:boolean;
    SolverVelocity:PKraftSolverVelocity;
    SolverPosition:PKraftSolverPosition;
    GyroscopicForce:TKraftVector3;
    Position,LinearVelocity,AngularVelocity,Translation,Rotation:TKraftVector3;
    Orientation:TKraftQuaternion;
begin

 Solver.Store;

 // Integrate velocities and create state buffers, calculate world inertia
 for i:=0 to CountRigidBodies-1 do begin

  RigidBody:=RigidBodies[i];

  Position:=RigidBody.Sweep.c;
  Orientation:=RigidBody.Sweep.q;
  RigidBody.Sweep.c0:=RigidBody.Sweep.c;
  RigidBody.Sweep.q0:=RigidBody.Sweep.q;

  if RigidBody.RigidBodyType=krbtDynamic then begin

   // Apply gravity force
   if krbfHasOwnGravity in RigidBody.Flags then begin
    RigidBody.Force:=Vector3Add(RigidBody.Force,Vector3ScalarMul(RigidBody.Gravity,RigidBody.Mass));
   end else begin
    RigidBody.Force:=Vector3Add(RigidBody.Force,Vector3ScalarMul(Physics.Gravity,RigidBody.Mass*RigidBody.GravityScale));
   end;

   // Calculate world space inertia tensor
   RigidBody.UpdateWorldInertiaTensor;

   // Apply gyroscopic force
   if RigidBody.EnableGyroscopicForce then begin
    // Gyroscopic force calculation using full newton-euler equations with implicit euler step, so it's stable.
    GyroscopicForce:=Vector3Sub(Vector3Sub(RigidBody.AngularVelocity,
                                           Vector3TermMatrixMulInverse(EvaluateEulerEquation(RigidBody.AngularVelocity,
                                                                                             RigidBody.AngularVelocity,
                                                                                             Vector3Origin,
                                                                                             TimeStep.DeltaTime,
                                                                                             RigidBody.WorldInertiaTensor),
                                                                       EvaluateEulerEquationDerivation(RigidBody.AngularVelocity,
                                                                                                       RigidBody.AngularVelocity,
                                                                                                       TimeStep.DeltaTime,
                                                                                                       RigidBody.WorldInertiaTensor))),
                                RigidBody.AngularVelocity);
    if (RigidBody.MaximalGyroscopicForce>EPSILON) and (Vector3LengthSquared(GyroscopicForce)>sqr(RigidBody.MaximalGyroscopicForce)) then begin
     Vector3Scale(GyroscopicForce,RigidBody.MaximalGyroscopicForce/Vector3Length(GyroscopicForce));
    end;
    RigidBody.Torque:=Vector3Add(RigidBody.Torque,GyroscopicForce);
   end;       

   // Integrate linear velocity
   RigidBody.LinearVelocity:=Vector3Add(RigidBody.LinearVelocity,Vector3ScalarMul(RigidBody.Force,RigidBody.InverseMass*TimeStep.DeltaTime));

   // Integrate angular velocity
   RigidBody.AngularVelocity:=Vector3Add(RigidBody.AngularVelocity,Vector3ScalarMul(Vector3TermMatrixMul(RigidBody.Torque,RigidBody.WorldInverseInertiaTensor),TimeStep.DeltaTime));

   if assigned(RigidBody.OnDamping) then begin
    RigidBody.OnDamping(RigidBody,TimeStep);
   end;

   // From Box2D
   // Apply damping.
   // ODE: dv/dt + c * v = 0
   // Solution: v(t) = v0 * exp(-c * t)
   // Time step: v(t + dt) = v0 * exp(-c * (t + dt)) = v0 * exp(-c * t) * exp(-c * dt) = v * exp(-c * dt)
   // v2 = exp(-c * dt) * v1
   // Pade approximation:
   // v2 = v1 * 1 / (1 + c * dt)
   Vector3Scale(RigidBody.LinearVelocity,1.0/(1.0+(RigidBody.LinearVelocityDamp*TimeStep.DeltaTime)));
   Vector3Scale(RigidBody.AngularVelocity,1.0/(1.0+(RigidBody.AngularVelocityDamp*TimeStep.DeltaTime)));

   // From PAPPE 1.0
   if RigidBody.AdditionalDamping then begin
    if (Vector3LengthSquared(RigidBody.LinearVelocity)<RigidBody.LinearVelocityAdditionalDampThresholdSqr) and
       (Vector3LengthSquared(RigidBody.AngularVelocity)<RigidBody.AngularVelocityAdditionalDampThresholdSqr) then begin
     Vector3Scale(RigidBody.LinearVelocity,RigidBody.AdditionalDamp);
     Vector3Scale(RigidBody.AngularVelocity,RigidBody.AdditionalDamp);
    end;
    s:=Vector3Length(RigidBody.LinearVelocity);
    if s<RigidBody.LinearVelocityDamp then begin
     if s>RigidBody.AdditionalDamp then begin
      RigidBody.LinearVelocity:=Vector3Sub(RigidBody.LinearVelocity,Vector3ScalarMul(Vector3NormEx(RigidBody.LinearVelocity),RigidBody.AdditionalDamp));
     end else begin
      RigidBody.LinearVelocity:=Vector3Origin;
     end;
    end;
    s:=Vector3Length(RigidBody.AngularVelocity);
    if s<RigidBody.AngularVelocityDamp then begin
     if s>RigidBody.AdditionalDamp then begin
      RigidBody.AngularVelocity:=Vector3Sub(RigidBody.AngularVelocity,Vector3ScalarMul(Vector3NormEx(RigidBody.AngularVelocity),RigidBody.AdditionalDamp));
     end else begin
      RigidBody.AngularVelocity:=Vector3Origin;
     end;
    end;
   end;

	end;

  // Transfer velocities
  SolverVelocity:=@Solver.Velocities[i];
  SolverVelocity^.LinearVelocity:=RigidBody.LinearVelocity;
  SolverVelocity^.AngularVelocity:=RigidBody.AngularVelocity;

  // Transfer positions
  SolverPosition:=@Solver.Positions[i];
  SolverPosition^.Position:=Position;
  SolverPosition^.Orientation:=Orientation;

 end;

 Solver.Initialize(TimeStep);

 Solver.InitializeConstraints;

 if Physics.WarmStarting then begin
  Solver.WarmStart;
 end;

 for i:=0 to CountConstraints-1 do begin
  Constraint:=Constraints[i];
  if assigned(Constraint) then begin
   Constraint.InitializeConstraintsAndWarmStart(self,TimeStep);
  end;
 end;
 for Iteration:=1 to Physics.VelocityIterations do begin
  for i:=0 to CountConstraints-1 do begin
   Constraint:=Constraints[i];
   if assigned(Constraint) and not (kcfBreaked in Constraint.Flags) then begin
    if ((Constraint.Flags*[kcfActive,kcfBreakable,kcfBreaked])=[kcfActive,kcfBreakable]) and
       ((Vector3Length(Constraint.GetReactionForce(TimeStep.InverseDeltaTime))>Constraint.BreakThresholdForce) or
        (Vector3Length(Constraint.GetReactionTorque(TimeStep.InverseDeltaTime))>Constraint.BreakThresholdTorque)) then begin
     Constraint.Flags:=Constraint.Flags+[kcfBreaked,kcfFreshBreaked];
     continue;
    end;
    Constraint.SolveVelocityConstraint(self,TimeStep);
   end;
  end;
  Solver.SolveVelocityConstraints;
 end;
 Solver.StoreImpulses;

 for i:=0 to CountRigidBodies-1 do begin

  RigidBody:=RigidBodies[i];

  if RigidBody.RigidBodyType=krbtDynamic then begin

   SolverPosition:=@Solver.Positions[i];
   Position:=SolverPosition^.Position;
   Orientation:=SolverPosition^.Orientation;

   SolverVelocity:=@Solver.Velocities[i];
   LinearVelocity:=SolverVelocity^.LinearVelocity;
   AngularVelocity:=SolverVelocity^.AngularVelocity;

// writeln(Vector3Length(LinearVelocity)*TimeStep.DeltaTime:1:8);

   if Physics.MaximalLinearVelocity>EPSILON then begin
    Translation:=Vector3ScalarMul(LinearVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Translation)>sqr(Physics.MaximalLinearVelocity) then begin
     Vector3Scale(LinearVelocity,Physics.MaximalLinearVelocity/Vector3Length(Translation));
    end;
   end;
   if RigidBody.MaximalLinearVelocity>EPSILON then begin
    Translation:=Vector3ScalarMul(LinearVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Translation)>sqr(RigidBody.MaximalLinearVelocity) then begin
     Vector3Scale(LinearVelocity,RigidBody.MaximalLinearVelocity/Vector3Length(Translation));
    end;
   end;

   if Physics.MaximalAngularVelocity>EPSILON then begin
    Rotation:=Vector3ScalarMul(AngularVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Rotation)>sqr(Physics.MaximalAngularVelocity) then begin
     Vector3Scale(AngularVelocity,Physics.MaximalAngularVelocity/Vector3Length(Rotation));
    end;
   end;
   if RigidBody.MaximalAngularVelocity>EPSILON then begin
    Rotation:=Vector3ScalarMul(AngularVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Rotation)>sqr(RigidBody.MaximalAngularVelocity) then begin
     Vector3Scale(AngularVelocity,RigidBody.MaximalAngularVelocity/Vector3Length(Rotation));
    end;
   end;

   Physics.Integrate(Position,Orientation,LinearVelocity,AngularVelocity,TimeStep.DeltaTime);

   SolverPosition^.Position:=Position;
   SolverPosition^.Orientation:=Orientation;
   SolverVelocity^.LinearVelocity:=LinearVelocity;
   SolverVelocity^.AngularVelocity:=AngularVelocity;

  end;

 end;

 for i:=0 to CountConstraints-1 do begin
  Constraint:=Constraints[i];
  if assigned(Constraint) and
     (((Constraint.Flags*[kcfActive,kcfBreakable,kcfBreaked])=[kcfActive,kcfBreakable]) and
      ((Vector3Length(Constraint.GetReactionForce(TimeStep.InverseDeltaTime))>Constraint.BreakThresholdForce) or
       (Vector3Length(Constraint.GetReactionTorque(TimeStep.InverseDeltaTime))>Constraint.BreakThresholdTorque))) then begin
   Constraint.Flags:=Constraint.Flags+[kcfBreaked,kcfFreshBreaked];
  end;
 end;

 for Iteration:=1 to Physics.PositionIterations do begin
  OK:=true;
  if not Solver.SolvePositionConstraints then begin
   OK:=false;
  end;
  for i:=0 to CountConstraints-1 do begin
   Constraint:=Constraints[i];
   if assigned(Constraint) and not (kcfBreaked in Constraint.Flags) then begin
    if not Constraint.SolvePositionConstraint(self,TimeStep) then begin
     OK:=false;
    end;
   end;
  end;
  if OK then begin
   break;
  end;
 end;

 for i:=0 to CountRigidBodies-1 do begin
  RigidBody:=RigidBodies[i];
  if RigidBody.RigidBodyType=krbtDynamic then begin

   SolverPosition:=@Solver.Positions[i];
   RigidBody.Sweep.c:=SolverPosition^.Position;
   RigidBody.Sweep.q:=SolverPosition^.Orientation;

   SolverVelocity:=@Solver.Velocities[i];
   RigidBody.LinearVelocity:=SolverVelocity^.LinearVelocity;
   RigidBody.AngularVelocity:=SolverVelocity^.AngularVelocity;

   RigidBody.SynchronizeTransformIncludingShapes;
   RigidBody.UpdateWorldInertiaTensor;
  end;
 end;

 if Physics.AllowSleep then begin

  // Find minimum sleep time of the entire island
  MinSleepTime:=3.40e+38;
  First:=true;
  for i:=0 to CountRigidBodies-1 do begin
   RigidBody:=RigidBodies[i];
   if RigidBody.RigidBodyType<>krbtStatic then begin
    if (Vector3LengthSquared(RigidBody.LinearVelocity)>sqr(Physics.LinearVelocityThreshold)) or
       (Vector3LengthSquared(RigidBody.AngularVelocity)>sqr(Physics.AngularVelocityThreshold)) then begin
     MinSleepTime:=0.0;
     RigidBody.SleepTime:=0.0;
     First:=false;
    end else if krbfAllowSleep in RigidBody.Flags then begin
     RigidBody.SleepTime:=RigidBody.SleepTime+TimeStep.DeltaTime;
     if First or (MinSleepTime>RigidBody.SleepTime) then begin
      First:=false;
      MinSleepTime:=RigidBody.SleepTime;
     end;
    end;
   end;
  end;

	// Put entire island to sleep so long as the minimum found sleep time is below the threshold.
  // If the minimum sleep time reaches below the sleeping threshold, the entire island will be
  // reformed next step and sleep test will be tried again.
  if MinSleepTime>Physics.SleepTimeThreshold then begin
   for i:=0 to CountRigidBodies-1 do begin
    if krbfAllowSleep in RigidBodies[i].Flags then begin
     RigidBodies[i].SetToSleep;
    end;
   end;
  end;

 end;

end;

procedure TKraftIsland.SolveTimeOfImpact(const TimeStep:TKraftTimeStep;const IndexA,IndexB:longint);
var Iteration,i:longint;
    RigidBody:TKraftRigidBody;
    SolverVelocity:PKraftSolverVelocity;
    SolverPosition:PKraftSolverPosition;
    Position,LinearVelocity,AngularVelocity,Translation,Rotation:TKraftVector3;
    Orientation:TKraftQuaternion;
begin

 Solver.Store;

 // Integrate velocities and create state buffers
 for i:=0 to CountRigidBodies-1 do begin
  RigidBody:=RigidBodies[i];
  SolverVelocity:=@Solver.Velocities[i];
  SolverVelocity^.LinearVelocity:=RigidBody.LinearVelocity;
  SolverVelocity^.AngularVelocity:=RigidBody.AngularVelocity;
  SolverPosition:=@Solver.Positions[i];
  SolverPosition^.Position:=RigidBody.Sweep.c;
  SolverPosition^.Orientation:=RigidBody.Sweep.q;
 end;

 Solver.Initialize(TimeStep);

 for Iteration:=0 to Physics.TimeOfImpactIterations-1 do begin
  if Solver.SolveTimeOfImpactConstraints(IndexA,IndexB) then begin
   break;
  end;
 end;

 // Leap of faith to new safe state.
 for i:=0 to CountRigidBodies-1 do begin
  RigidBody:=RigidBodies[i];
  if RigidBody.RigidBodyType=krbtDynamic then begin
   SolverPosition:=@Solver.Positions[i];
   RigidBody.Sweep.c0:=SolverPosition^.Position;
   RigidBody.Sweep.q0:=SolverPosition^.Orientation;
  end;
 end;

 Solver.InitializeConstraints;

 // No warm starting is needed for TOI events because warm
 // starting impulses were applied in the discrete solver.

 for Iteration:=0 to Physics.VelocityIterations-1 do begin
  Solver.SolveVelocityConstraints;
 end;

 // Don't store the TOI contact forces for warm starting
 // because they can be quite large.
                       
 for i:=0 to CountRigidBodies-1 do begin

  RigidBody:=RigidBodies[i];

  if RigidBody.RigidBodyType=krbtDynamic then begin

   SolverPosition:=@Solver.Positions[i];
   Position:=SolverPosition^.Position;
   Orientation:=SolverPosition^.Orientation;

   SolverVelocity:=@Solver.Velocities[i];
   LinearVelocity:=SolverVelocity^.LinearVelocity;
   AngularVelocity:=SolverVelocity^.AngularVelocity;

   if Physics.MaximalLinearVelocity>EPSILON then begin
    Translation:=Vector3ScalarMul(LinearVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Translation)>sqr(Physics.MaximalLinearVelocity) then begin
     Vector3Scale(LinearVelocity,Physics.MaximalLinearVelocity/Vector3Length(Translation));
    end;
   end;
   if RigidBody.MaximalLinearVelocity>EPSILON then begin
    Translation:=Vector3ScalarMul(LinearVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Translation)>sqr(RigidBody.MaximalLinearVelocity) then begin
     Vector3Scale(LinearVelocity,RigidBody.MaximalLinearVelocity/Vector3Length(Translation));
    end;
   end;

   if Physics.MaximalAngularVelocity>EPSILON then begin
    Rotation:=Vector3ScalarMul(AngularVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Rotation)>sqr(Physics.MaximalAngularVelocity) then begin
     Vector3Scale(AngularVelocity,Physics.MaximalAngularVelocity/Vector3Length(Rotation));
    end;
   end;
   if RigidBody.MaximalAngularVelocity>EPSILON then begin
    Rotation:=Vector3ScalarMul(AngularVelocity,TimeStep.DeltaTime);
    if Vector3LengthSquared(Rotation)>sqr(RigidBody.MaximalAngularVelocity) then begin
     Vector3Scale(AngularVelocity,RigidBody.MaximalAngularVelocity/Vector3Length(Rotation));
    end;
   end;

   Physics.Integrate(Position,Orientation,LinearVelocity,AngularVelocity,TimeStep.DeltaTime);

   RigidBody.Sweep.c:=Position;
   RigidBody.Sweep.q:=Orientation;

   RigidBody.LinearVelocity:=LinearVelocity;
   RigidBody.AngularVelocity:=AngularVelocity;

   RigidBody.SynchronizeTransformIncludingShapes;
   RigidBody.UpdateWorldInertiaTensor;
  end;
 end;

end;

constructor TKraftJobThread.Create(const APhysics:TKraft;const AJobManager:TKraftJobManager;const AThreadNumber:longint);
begin
//{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
 Physics:=APhysics;
 JobManager:=AJobManager;
 ThreadNumber:=AThreadNumber;
 Event:=TEvent.Create(nil,false,false,'');
 DoneEvent:=TEvent.Create(nil,false,false,'');
//{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
 inherited Create(false);
end;

destructor TKraftJobThread.Destroy;
begin
//{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
 FreeAndNil(Event);
 FreeAndNil(DoneEvent);
//{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
 inherited Destroy;
end;

procedure TKraftJobThread.Execute;
var JobIndex:longint;
begin
 SetPrecisionMode(PhysicsFPUPrecisionMode);
 SetExceptionMask(PhysicsFPUExceptionMask);
 SIMDSetOurFlags;
 InterlockedIncrement(JobManager.CountAliveThreads);
 while not (Terminated or JobManager.ThreadsTerminated) do begin
  Event.WaitFor(INFINITE);
  if Terminated or JobManager.ThreadsTerminated then begin
   break;
  end else begin
   repeat                       
    JobIndex:=InterlockedDecrement(JobManager.CountRemainJobs);
    if JobIndex>=0 then begin
     if assigned(JobManager.OnProcessJob) then begin
      JobManager.OnProcessJob(JobIndex,ThreadNumber);
     end;
    end else begin
     break;
    end;
   until false;
   DoneEvent.SetEvent;
  end;
 end;
 InterlockedDecrement(JobManager.CountAliveThreads);
end;

constructor TKraftJobManager.Create(const APhysics:TKraft);
var i:longint;
begin
 inherited Create;
 Physics:=APhysics;
 Threads:=nil;
 CountThreads:=APhysics.CountThreads;
 SetLength(Threads,CountThreads);
 CountAliveThreads:=0;
 ThreadsTerminated:=false;
 OnProcessJob:=nil;
 for i:=0 to CountThreads-1 do begin
  Threads[i]:=TKraftJobThread.Create(Physics,self,i);
  Threads[i].Priority:=tpHigher;
 end;
end;

destructor TKraftJobManager.Destroy;
var i:longint;
begin
 ThreadsTerminated:=true;
 for i:=0 to CountThreads-1 do begin
  Threads[i].Terminate;
  Threads[i].Event.SetEvent;
  Threads[i].WaitFor;
  FreeAndNil(Threads[i]);
 end;
 SetLength(Threads,0);
 inherited Destroy;
end;

procedure TKraftJobManager.WakeUp;
var i:longint;
begin
 for i:=0 to CountThreads-1 do begin
  Threads[i].Event.SetEvent;
 end;
end;

procedure TKraftJobManager.WaitFor;
var i:longint;
begin
 for i:=0 to CountThreads-1 do begin
  Threads[i].DoneEvent.WaitFor(INFINITE);
 end;
end;

procedure TKraftJobManager.ProcessJobs;
begin
 WakeUp;
 WaitFor;
end;

constructor TKraft.Create(const ACountThreads:longint=-1);
const TriangleVertex0:TKraftVector3=(x:0.0;y:0.0;z:0.0);
      TriangleVertex1:TKraftVector3=(x:1.0;y:0.0;z:0.01);
      TriangleVertex2:TKraftVector3=(x:0.0;y:1.0;z:0.02);
var Index:longint;
{$ifdef win32}
    i,j:longint;
    sinfo:SYSTEM_INFO;
    dwProcessAffinityMask,dwSystemAffinityMask:ptruint;
 function GetRealCountOfCPUCores:longint; {$ifdef caninline}inline;{$endif}
 const RelationProcessorCore=0;
       RelationNumaNode=1;
       RelationCache=2;
       RelationProcessorPackage=3;
       RelationGroup=4;
       RelationAll=$ffff;
       CacheUnified=0;
       CacheInstruction=1;
       CacheData=2;
       CacheTrace=3;
 type TLogicalProcessorRelationship=dword;
      TProcessorCacheType=dword;
      TCacheDescriptor=packed record
       Level:byte;
       Associativity:byte;
       LineSize:word;
       Size:dword;
       pcType:TProcessorCacheType;
      end;
      PSystemLogicalProcessorInformation=^TSystemLogicalProcessorInformation;
      TSystemLogicalProcessorInformation=packed record
       ProcessorMask:ptruint;
       case Relationship:TLogicalProcessorRelationship of
        0:(
         Flags:byte;
        );
        1:(
         NodeNumber:dword;
        );
        2:(
         Cache:TCacheDescriptor;
        );
        3:(
         Reserved:array[0..1] of int64;
        );
      end;
      TGetLogicalProcessorInformation=function(Buffer:PSystemLogicalProcessorInformation;out ReturnLength:DWORD):BOOL; stdcall;
 var GetLogicalProcessorInformation:TGetLogicalProcessorInformation;
     Buffer:array of TSystemLogicalProcessorInformation;
     ReturnLength:dword;
     Index,Count:longint;
 begin
  result:=-1;
  Buffer:=nil;
  try
   GetLogicalProcessorInformation:=GetProcAddress(GetModuleHandle('kernel32'),'GetLogicalProcessorInformation');
   if assigned(GetLogicalProcessorInformation) then begin
    SetLength(Buffer,16);
    Count:=0;
    repeat
     ReturnLength:=length(Buffer)*SizeOf(TSystemLogicalProcessorInformation);
     if GetLogicalProcessorInformation(@Buffer[0],ReturnLength) then begin
      Count:=ReturnLength div SizeOf(TSystemLogicalProcessorInformation);
     end else begin
      if GetLastError=ERROR_INSUFFICIENT_BUFFER then begin
       SetLength(Buffer,(ReturnLength div SizeOf(TSystemLogicalProcessorInformation))+1);
       continue;
      end;
     end;
     break;
    until false;
    if Count>0 then begin
     result:=0;
     for Index:=0 to Count-1 do begin
      if Buffer[Index].Relationship=RelationProcessorCore then begin
       inc(result);
      end;
     end;
    end;
   end;
  finally
   SetLength(Buffer,0);
  end;
 end;
{$endif}
begin
 inherited Create;

 HighResolutionTimer:=TKraftHighResolutionTimer.Create;

 IsSolving:=false;

 CountThreads:=ACountThreads;

{$ifdef win32}
 if CountThreads<0 then begin
  CountThreads:=GetRealCountOfCPUCores;
  GetSystemInfo(sinfo);
  GetProcessAffinityMask(GetCurrentProcess,dwProcessAffinityMask,dwSystemAffinityMask);
  j:=0;
  for i:=0 to sinfo.dwNumberOfProcessors-1 do begin
   if (dwProcessAffinityMask and (1 shl i))<>0 then begin
    inc(j);
    if j>=MAX_THREADS then begin
     break;
    end;
   end;
  end;
  if (CountThreads<0) or (CountThreads>j) then begin
   CountThreads:=j;
  end;
 end;
{$endif}

 CountThreads:=Min(Max(CountThreads,0),MAX_THREADS);

 NewShapes:=false;

 ConvexHullFirst:=nil;
 ConvexHullLast:=nil;

 MeshFirst:=nil;
 MeshLast:=nil;

 ConstraintFirst:=nil;
 ConstraintLast:=nil;

 CountRigidBodies:=0;
 RigidBodyIDCounter:=0;

 RigidBodyFirst:=nil;
 RigidBodyLast:=nil;

 StaticRigidBodyCount:=0;

 StaticRigidBodyFirst:=nil;
 StaticRigidBodyLast:=nil;

 DynamicRigidBodyCount:=0;

 DynamicRigidBodyFirst:=nil;
 DynamicRigidBodyLast:=nil;

 KinematicRigidBodyCount:=0;

 KinematicRigidBodyFirst:=nil;
 KinematicRigidBodyLast:=nil;

 StaticAABBTree:=TKraftDynamicAABBTree.Create;
 SleepingAABBTree:=TKraftDynamicAABBTree.Create;
 DynamicAABBTree:=TKraftDynamicAABBTree.Create;
 KinematicAABBTree:=TKraftDynamicAABBTree.Create;

 Islands:=nil;
 SetLength(Islands,16);
 for Index:=0 to length(Islands)-1 do begin
  Islands[Index]:=TKraftIsland.Create(self,Index);
 end;
 CountIslands:=0;

 BroadPhase:=TKraftBroadPhase.Create(self);

 ContactManager:=TKraftContactManager.Create(self);

 WorldFrequency:=60.0;

 WorldDeltaTime:=1.0/WorldFrequency;

 WorldInverseDeltaTime:=WorldFrequency;

 LastInverseDeltaTime:=0.0;

 AllowSleep:=true;

 AllowedPenetration:=0.0;

 Gravity.x:=0.0;
 Gravity.y:=-9.83;
 Gravity.z:=0.0;

 MaximalLinearVelocity:=1000.0;

 MaximalAngularVelocity:=0.0;//pi*0.5;

 LinearVelocityThreshold:=0.1;

 AngularVelocityThreshold:=2.0*(pi/180.0);

 SleepTimeThreshold:=0.5;

 Baumgarte:=0.2;

 TimeOfImpactBaumgarte:=0.75;

 PenetrationSlop:=0.05;

 LinearSlop:=0.005;

 AngularSlop:=(2.0/180.0)*pi;

 MaximalLinearCorrection:=0.2;

 MaximalAngularCorrection:=(8.0/180.0)*pi;

 WarmStarting:=true;
 
 ContinuousMode:=kcmNone;
//ContinuousMode:=kcmMotionClamping;
//ContinuousMode:=kcmTimeOfImpactSubSteps;

 ContinuousAgainstDynamics:=false;

//TimeOfImpactAlgorithm:=ktoiaConservativeAdvancement;
 TimeOfImpactAlgorithm:=ktoiaBilateralAdvancement;

 MaximalSubSteps:=16;

 VelocityIterations:=10;

 PositionIterations:=4;

 TimeOfImpactIterations:=20;

 PerturbationIterations:=MAX_CONTACTS;
                          
 AlwaysPerturbating:=false;

 EnableFriction:=true;

 LinearVelocityRK4Integration:=false;

 AngularVelocityRK4Integration:=false;

 ContactBreakingThreshold:=0.02;
               
 TriangleShapes:=nil;
 SetLength(TriangleShapes,Max(1,CountThreads));
 for Index:=0 to length(TriangleShapes)-1 do begin
  TriangleShapes[Index]:=TKraftShapeTriangle.Create(self,nil,TriangleVertex0,TriangleVertex1,TriangleVertex2);
  TriangleShapes[Index].UpdateShapeAABB;
  TriangleShapes[Index].CalculateMassData;
 end;

 if CountThreads>1 then begin
  JobManager:=TKraftJobManager.Create(self);
 end else begin
  JobManager:=nil;
 end;

 SIMDSetOurFlags;

end;

destructor TKraft.Destroy;
var Index:longint;
begin

 if assigned(JobManager) then begin
  FreeAndNil(JobManager);
 end;

 for Index:=0 to length(TriangleShapes)-1 do begin
  TriangleShapes[Index].Free;
 end;
 SetLength(TriangleShapes,0);

 while assigned(ConstraintLast) do begin
  ConstraintLast.Free;
 end;

 while assigned(RigidBodyLast) do begin
  RigidBodyLast.Free;
 end;

 while assigned(MeshLast) do begin
  MeshLast.Free;
 end;

 while assigned(ConvexHullLast) do begin
  ConvexHullLast.Free;
 end;

 BroadPhase.Free;

 StaticAABBTree.Free;
 SleepingAABBTree.Free;
 DynamicAABBTree.Free;
 KinematicAABBTree.Free;

 for Index:=0 to length(Islands)-1 do begin
  Islands[Index].Free;
 end;
 SetLength(Islands,0);

 ContactManager.Free;

 HighResolutionTimer.Free;

 inherited Destroy;
end;

procedure TKraft.SetFrequency(const AFrequency:TKraftScalar);
begin
 WorldFrequency:=AFrequency;
 WorldDeltaTime:=1.0/WorldFrequency;
 WorldInverseDeltaTime:=WorldFrequency;
end;

procedure TKraft.Integrate(var Position:TKraftVector3;var Orientation:TKraftQuaternion;const LinearVelocity,AngularVelocity:TKraftVector3;const DeltaTime:TKraftScalar);
const OneDiv3=1.0/3.0;
      OneDiv6=1.0/6.0;
      OneDiv24=1.0/24.0;
var {ThetaLenSquared,ThetaLen,s,w,}DeltaTimeDiv6,DeltaTimeDiv3:TKraftScalar;
//  Theta:TKraftVector3;
    HalfSpinQuaternion:TKraftQuaternion;
    Quaternions:array[0..3] of TKraftQuaternion;
    Positions:array[0..3] of TKraftVector3;
begin

 DeltaTimeDiv6:=DeltaTime*OneDiv6;
 DeltaTimeDiv3:=DeltaTime*OneDiv3;

 if LinearVelocityRK4Integration then begin
  Positions[0]:=LinearVelocity;
  Positions[1]:=Vector3Add(Positions[0],Vector3ScalarMul(LinearVelocity,DeltaTime*0.5));
  Positions[2]:=Vector3Add(Positions[1],Vector3ScalarMul(LinearVelocity,DeltaTime*0.5));
  Positions[3]:=Vector3Add(Positions[2],Vector3ScalarMul(LinearVelocity,DeltaTime));
  Vector3DirectAdd(Position,
                       Vector3Add(Vector3ScalarMul(Vector3Add(Positions[0],Positions[3]),DeltaTimeDiv6),
                                      Vector3ScalarMul(Vector3Add(Positions[1],Positions[2]),DeltaTimeDiv3)));
 end else begin
  Vector3DirectAdd(Position,Vector3ScalarMul(LinearVelocity,DeltaTime));
 end;

 if AngularVelocityRK4Integration then begin
  HalfSpinQuaternion.x:=AngularVelocity.x*0.5;
  HalfSpinQuaternion.y:=AngularVelocity.y*0.5;
  HalfSpinQuaternion.z:=AngularVelocity.z*0.5;
  HalfSpinQuaternion.w:=0;
  Quaternions[0]:=QuaternionMul(HalfSpinQuaternion,QuaternionTermNormalize(Orientation));
  Quaternions[1]:=QuaternionMul(HalfSpinQuaternion,QuaternionTermNormalize(QuaternionAdd(Orientation,QuaternionScalarMul(Quaternions[0],DeltaTime*0.5))));
  Quaternions[2]:=QuaternionMul(HalfSpinQuaternion,QuaternionTermNormalize(QuaternionAdd(Orientation,QuaternionScalarMul(Quaternions[1],DeltaTime*0.5))));
  Quaternions[3]:=QuaternionMul(HalfSpinQuaternion,QuaternionTermNormalize(QuaternionAdd(Orientation,QuaternionScalarMul(Quaternions[2],DeltaTime))));
  Orientation:=QuaternionTermNormalize(QuaternionAdd(Orientation,
                                                     QuaternionAdd(QuaternionScalarMul(QuaternionAdd(Quaternions[0],Quaternions[3]),DeltaTimeDiv6),
                                                     QuaternionScalarMul(QuaternionAdd(Quaternions[1],Quaternions[2]),DeltaTimeDiv3))));
 end else begin
  HalfSpinQuaternion.x:=AngularVelocity.x;
  HalfSpinQuaternion.y:=AngularVelocity.y;
  HalfSpinQuaternion.z:=AngularVelocity.z;
  HalfSpinQuaternion.w:=0;
  Orientation:=QuaternionTermNormalize(QuaternionAdd(Orientation,QuaternionMul(QuaternionScalarMul(HalfSpinQuaternion,DeltaTime*0.5),Orientation)));{}
//Orientation:=QuaternionTermNormalize(QuaternionIntegrate(Orientation,AngularVelocity,DeltaTime));
{ Theta:=Vector3ScalarMul(AngularVelocity,DeltaTime*0.5);
  ThetaLenSquared:=Vector3LengthSquared(Theta);
  if (sqr(ThetaLenSquared)*OneDiv24)<EPSILON then begin
   w:=1.0-(ThetaLenSquared*0.5);
   s:=1.0-(ThetaLenSquared*OneDiv6);
  end else begin
   ThetaLen:=sqrt(ThetaLenSquared);
   w:=cos(ThetaLen);
   s:=sin(ThetaLen)/ThetaLen;
  end;
  Quaternions[0].x:=Theta.x*s;
  Quaternions[0].y:=Theta.y*s;
  Quaternions[0].z:=Theta.z*s;
  Quaternions[0].w:=w;
  Orientation:=QuaternionTermNormalize(QuaternionMul(Quaternions[0],Orientation));{}
 end;

end;

procedure TKraft.BuildIslands;
var IslandIndex,LastCount,SubIndex:longint;
    SeedRigidBody,SeedRigidBodyStack,CurrentRigidBody,OtherRigidBody,StaticRigidBodiesList:TKraftRigidBody;
    CurrentConstraintEdge:PKraftConstraintEdge;
    CurrentConstraint:TKraftConstraint;
    Island:TKraftIsland;
    ContactPairEdge:PKraftContactPairEdge;
    ContactPair:PKraftContactPair;
begin

 if CountRigidBodies>length(Islands) then begin
  LastCount:=length(Islands);
  SetLength(Islands,CountRigidBodies*2);
  for SubIndex:=LastCount to length(Islands)-1 do begin
   Islands[SubIndex]:=TKraftIsland.Create(self,SubIndex);
  end;
 end;

 CurrentRigidBody:=RigidBodyFirst;
 while assigned(CurrentRigidBody) do begin
  CurrentRigidBody.Island:=nil;
  CurrentRigidBody.Flags:=CurrentRigidBody.Flags-[krbfIslandVisited,krbfIslandStatic];
//Exclude(ContactPair^.Flags,[krbfIslandVisited,krbfIslandStatic]);
  CurrentRigidBody:=CurrentRigidBody.RigidBodyNext;
 end;

 CurrentConstraint:=ConstraintFirst;
 while assigned(CurrentConstraint) do begin
  Exclude(CurrentConstraint.Flags,kcfVisited);
  CurrentConstraint:=CurrentConstraint.Next;
 end;

 ContactPair:=ContactManager.ContactPairFirst;
 while assigned(ContactPair) do begin
  ContactPair.Island:=nil;
  Exclude(ContactPair^.Flags,kcfInIsland);
  ContactPair:=ContactPair^.Next;
 end;

 CountIslands:=0;

 SeedRigidBody:=RigidBodyFirst;
 while assigned(SeedRigidBody) do begin

  if (krbfIslandVisited in SeedRigidBody.Flags) or                                // Seed can't be visited and apart of an island already
     ((SeedRigidBody.Flags*[krbfAwake,krbfActive])<>[krbfAwake,krbfActive]) or // Seed must be awake
     (SeedRigidBody.RigidBodyType=krbtStatic) then begin                          // Seed can't be a static body in order to keep islands as small as possible
   SeedRigidBody:=SeedRigidBody.RigidBodyNext;
   continue;
  end;

  // Allocate island
  IslandIndex:=CountIslands;
  inc(CountIslands);
  if CountIslands>length(Islands) then begin
   LastCount:=length(Islands);
   SetLength(Islands,CountIslands*2);
   for SubIndex:=LastCount to length(Islands)-1 do begin
    Islands[SubIndex]:=TKraftIsland.Create(self,SubIndex);
   end;
  end;
  Island:=Islands[IslandIndex];
  Island.Clear;

  StaticRigidBodiesList:=nil;

  // Add first rigid body to the stack
  Include(SeedRigidBody.Flags,krbfIslandVisited);
  SeedRigidBody.NextOnIslandBuildStack:=nil;
  SeedRigidBodyStack:=SeedRigidBody;

  // Process seed rigid body loop
  while assigned(SeedRigidBodyStack) do begin

   // Pop next rigid body from the stack
   CurrentRigidBody:=SeedRigidBodyStack;
   SeedRigidBodyStack:=CurrentRigidBody.NextOnIslandBuildStack;
   CurrentRigidBody.NextOnIslandBuildStack:=nil;

   // Add to the island
   Island.AddRigidBody(CurrentRigidBody);

   // Awaken all bodies connected to the island
   CurrentRigidBody.SetToAwake;  

   // Do not search across static bodies to keep island formations as small as possible, however the static
   // body itself should be apart of the island in order to properly represent a full contact
   if CurrentRigidBody.RigidBodyType=krbtStatic then begin

    if not (krbfIslandStatic in CurrentRigidBody.Flags) then begin
     Include(CurrentRigidBody.Flags,krbfIslandStatic);
     CurrentRigidBody.NextStaticRigidBody:=StaticRigidBodiesList;
     StaticRigidBodiesList:=CurrentRigidBody;
    end;

    continue;
   end;

   // Process all contact pairs
   if not (krbfSensor in CurrentRigidBody.Flags) then begin
    ContactPairEdge:=CurrentRigidBody.ContactPairEdgeFirst;
    while assigned(ContactPairEdge) do begin
     ContactPair:=ContactPairEdge^.ContactPair;
     // Skip contacts that have been added to an island already and we can safely skip contacts if these didn't actually collide with anything,
     // and skip also sensors
     if ((ContactPair^.Flags*[kcfColliding,kcfInIsland])=[kcfColliding]) and
        not ((ksfSensor in ContactPair^.Shapes[0].Flags) or
             (ksfSensor in ContactPair^.Shapes[1].Flags)) then begin
      ContactPair^.Flags:=ContactPair^.Flags+[kcfInIsland];
      Island.AddContactPair(ContactPair);
      OtherRigidBody:=ContactPairEdge^.OtherRigidBody;
      if assigned(OtherRigidBody) and ((OtherRigidBody.Flags*[krbfIslandVisited,krbfSensor])=[]) then begin
       Include(OtherRigidBody.Flags,krbfIslandVisited);
       OtherRigidBody.NextOnIslandBuildStack:=SeedRigidBodyStack;
       SeedRigidBodyStack:=OtherRigidBody;
      end;
     end;
     ContactPairEdge:=ContactPairEdge^.Next;
    end;
   end;

   // Process all collected constraints
   CurrentConstraintEdge:=CurrentRigidBody.ConstraintEdgeFirst;
   while assigned(CurrentConstraintEdge) do begin
    CurrentConstraint:=CurrentConstraintEdge^.Constraint;
    if (assigned(CurrentConstraint) and not (kcfVisited in CurrentConstraint.Flags)) and ((CurrentConstraint.Flags*[kcfActive,kcfBreaked])=[kcfActive]) then begin
     Include(CurrentConstraint.Flags,kcfVisited);
     Island.AddConstraint(CurrentConstraint);
     OtherRigidBody:=CurrentConstraintEdge^.OtherRigidBody;
     if (OtherRigidBody<>CurrentRigidBody) and assigned(OtherRigidBody) and ((OtherRigidBody.Flags*[krbfIslandVisited,krbfSensor])=[]) then begin
      Include(OtherRigidBody.Flags,krbfIslandVisited);
      OtherRigidBody.NextOnIslandBuildStack:=SeedRigidBodyStack;
      SeedRigidBodyStack:=OtherRigidBody;
     end;
    end;
    CurrentConstraintEdge:=CurrentConstraintEdge^.Next;
   end;

  end;

  Island.MergeContactPairs;

  // Allow static bodies and with these collected constraints to participate in other islands
  while assigned(StaticRigidBodiesList) do begin
   CurrentRigidBody:=StaticRigidBodiesList;
   CurrentConstraintEdge:=CurrentRigidBody.ConstraintEdgeFirst;
   while assigned(CurrentConstraintEdge) do begin
    CurrentConstraint:=CurrentConstraintEdge^.Constraint;
    if assigned(CurrentConstraint) then begin
     Exclude(CurrentConstraint.Flags,kcfVisited);
    end;
    CurrentConstraintEdge:=CurrentConstraintEdge^.Next;
   end;
   StaticRigidBodiesList:=CurrentRigidBody.NextStaticRigidBody;
   CurrentRigidBody.Flags:=CurrentRigidBody.Flags-[krbfIslandVisited,krbfIslandStatic];
  end;

  SeedRigidBody:=SeedRigidBody.RigidBodyNext;

 end;

end;

procedure TKraft.ProcessSolveIslandJob(const JobIndex,ThreadIndex:longint);
begin
 Islands[JobIndex].Solve(JobTimeStep);
end;

procedure TKraft.SolveIslands(const TimeStep:TKraftTimeStep);
var Index:longint;
begin
 JobTimeStep:=TimeStep;
 IsSolving:=true;
 if assigned(JobManager) then begin
  JobManager.OnProcessJob:=ProcessSolveIslandJob;
  JobManager.CountRemainJobs:=CountIslands;
  JobManager.ProcessJobs;
 end else begin
  for Index:=0 to CountIslands-1 do begin
   Islands[Index].Solve(JobTimeStep);
  end;
 end;
 IsSolving:=false;
end;

// Conservative advancement
function TKraft.GetConservativeAdvancementTimeOfImpact(const ShapeA:TKraftShape;const SweepA:TKraftSweep;const ShapeB:TKraftShape;const ShapeBTriangleIndex:longint;const SweepB:TKraftSweep;const TimeStep:TKraftTimeStep;const ThreadIndex:longint;var Beta:TKraftScalar):boolean;
const Radius=1e-3;
var Tries:longint;
    BoundingRadiusA,BoundingRadiusB,MaximumAngularProjectedVelocity,RelativeLinearVelocityLength,Lambda,LastLambda,
    ProjectedLinearVelocity,DistanceLambda,Distance,ContinuousMinimumRadiusScaleFactor:TKraftScalar;
    MeshShape:TKraftShapeMesh;
    MeshTriangle:PKraftMeshTriangle;
    ShapeTriangle:TKraftShapeTriangle;
    Shapes:array[0..1] of TKraftShape;
    RelativeLinearVelocity:TKraftVector3;
    LinearVelocities,AngularVelocities:array[0..1] of TKraftVector3;
    Transforms:array[0..1] of TKraftMatrix4x4;
    GJK:TKraftGJK;
begin

 result:=false;

 Shapes[0]:=ShapeA;

 if (ShapeBTriangleIndex>=0) and (ShapeB is TKraftShapeMesh) then begin
  MeshShape:=TKraftShapeMesh(ShapeB);
  ShapeTriangle:=TKraftShapeTriangle(TriangleShapes[ThreadIndex]);
  Shapes[1]:=ShapeTriangle;
  MeshTriangle:=@MeshShape.Mesh.Triangles[ShapeBTriangleIndex];
  ShapeTriangle.LocalTransform:=MeshShape.LocalTransform;
  ShapeTriangle.WorldTransform:=MeshShape.WorldTransform;
  ShapeTriangle.ConvexHull.Vertices[0].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[0]];
  ShapeTriangle.ConvexHull.Vertices[1].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[1]];
  ShapeTriangle.ConvexHull.Vertices[2].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[2]];
  ShapeTriangle.UpdateData;
 end else begin
  Shapes[1]:=ShapeB;
 end;

 CalculateVelocity(SweepA.c0,SweepA.q0,SweepA.c,SweepA.q,1.0,LinearVelocities[0],AngularVelocities[0]);
 CalculateVelocity(SweepB.c0,SweepB.q0,SweepB.c,SweepB.q,1.0,LinearVelocities[1],AngularVelocities[1]);

 BoundingRadiusA:=Shapes[0].AngularMotionDisc;
 BoundingRadiusB:=Shapes[1].AngularMotionDisc;

 MaximumAngularProjectedVelocity:=((Vector3Length(AngularVelocities[0])*BoundingRadiusA)+(Vector3Length(AngularVelocities[1])*BoundingRadiusB));

 RelativeLinearVelocity:=Vector3Sub(LinearVelocities[1],LinearVelocities[0]);

 RelativeLinearVelocityLength:=Vector3Length(RelativeLinearVelocity);

 if abs(RelativeLinearVelocityLength+MaximumAngularProjectedVelocity)<EPSILON then begin
  exit;
 end;

 ContinuousMinimumRadiusScaleFactor:=Max(ShapeA.ContinuousMinimumRadiusScaleFactor,ShapeB.ContinuousMinimumRadiusScaleFactor);

 if (ContinuousMinimumRadiusScaleFactor>EPSILON) and
    (RelativeLinearVelocityLength<Max(EPSILON,Min(Shapes[0].ShapeSphere.Radius,Shapes[1].ShapeSphere.Radius)*ContinuousMinimumRadiusScaleFactor)) then begin
  exit;
 end;

 Lambda:=0.0;

 LastLambda:=Lambda;

 GJK.CachedSimplex:=nil;
 GJK.Simplex.Count:=0;
 GJK.Shapes[0]:=Shapes[0];
 GJK.Shapes[1]:=Shapes[1];
 GJK.Transforms[0]:=@Transforms[0];
 GJK.Transforms[1]:=@Transforms[1];
 GJK.UseRadii:=true;

 Transforms[0]:=Matrix4x4TermMul(Shapes[0].LocalTransform,SweepTransform(SweepA,0.0));
 Transforms[1]:=Matrix4x4TermMul(Shapes[1].LocalTransform,SweepTransform(SweepB,0.0));

 if GJK.Run then begin

  Distance:=GJK.Distance+AllowedPenetration;

  ProjectedLinearVelocity:=Vector3Dot(RelativeLinearVelocity,GJK.Normal);
  if (ProjectedLinearVelocity+MaximumAngularProjectedVelocity)<=EPSILON then begin
   exit;
  end;

  Tries:=0;

  while Distance>Radius do begin

   ProjectedLinearVelocity:=Vector3Dot(RelativeLinearVelocity,GJK.Normal);
   if (ProjectedLinearVelocity+MaximumAngularProjectedVelocity)<=EPSILON then begin
    exit;
   end;

   DistanceLambda:=Distance/(ProjectedLinearVelocity+MaximumAngularProjectedVelocity);

   Lambda:=Lambda+DistanceLambda;
   if ((Lambda<0.0) or (Lambda>1.0)) or (Lambda<=LastLambda) then begin
    exit;
   end;

   LastLambda:=Lambda;

   Transforms[0]:=Matrix4x4TermMul(Shapes[0].LocalTransform,SweepTransform(SweepA,Lambda));
   Transforms[1]:=Matrix4x4TermMul(Shapes[1].LocalTransform,SweepTransform(SweepB,Lambda));

   if GJK.Run then begin

    Distance:=GJK.Distance+AllowedPenetration;

    inc(Tries);
    if Tries>TimeOfImpactMaximumIterations then begin
     exit;
    end;

   end else begin
    exit;
   end;

  end;

//writeln(Lambda:1:8);

  Beta:=Lambda;
  result:=true;

 end;

end;
  
// Bilateral advancement
function TKraft.GetBilateralAdvancementTimeOfImpact(const ShapeA:TKraftShape;const SweepA:TKraftSweep;const ShapeB:TKraftShape;const ShapeBTriangleIndex:longint;const SweepB:TKraftSweep;const TimeStep:TKraftTimeStep;const ThreadIndex:longint;var Beta:TKraftScalar):boolean;
const sfmNONE=0;
      sfmVERTICES=1;
      sfmEDGEA=2;
      sfmEDGEB=3;
      sfmFACEA=4;
      sfmFACEB=5;
      sfmEDGES=6;
var Iteration,TryIteration,RootIteration,SeparationFunctionMode:longint;
    Unprocessed,Overlapping:boolean;
    t0,t1,s0,s1,a0,a1,t,s,tS,tT0,tT1,TotalRadius,Target,Tolerance,Distance,CurrentDistance,L,
    ContinuousMinimumRadiusScaleFactor:TKraftScalar;
    ShapeTriangle:TKraftShapeTriangle;
    MeshShape:TKraftShapeMesh;
    MeshTriangle:PKraftMeshTriangle;
    Axis,LocalVertex,va,vb,eA,eB:TKraftVector3;
    LocalPlane:TKraftPlane;
    GJK:TKraftGJK;
    Shapes:array[0..1] of TKraftShape;
    WitnessPoints:array[0..1] of TKraftVector3;
    Transforms:array[0..1] of TKraftMatrix4x4;
    LinearVelocities,AngularVelocities:array[0..1] of TKraftVector3;
    UniqueGJKVertexIndices:array[0..1,0..2] of longint;
    UniqueGJKVertices:array[0..1,0..2] of TKraftVector3;
    CountUniqueGJKVertices:array[0..1] of longint;
 function Evaluate:TKraftScalar; {$ifdef caninline}inline;{$endif}
 begin
  case SeparationFunctionMode of
   sfmVERTICES:begin
    result:=Vector3Dot(Axis,
                           Vector3Sub(Vector3TermMatrixMul(WitnessPoints[1],Transforms[1]),
                                          Vector3TermMatrixMul(WitnessPoints[0],Transforms[0])));
   end;
   sfmEDGEA,sfmFACEA,sfmEDGES:begin
    result:=PlaneVectorDistance(LocalPlane,Vector3TermMatrixMulInverted(Vector3TermMatrixMul(WitnessPoints[1],Transforms[1]),Transforms[0]));
   end;
   sfmEDGEB,sfmFACEB:begin
    result:=PlaneVectorDistance(LocalPlane,Vector3TermMatrixMulInverted(Vector3TermMatrixMul(WitnessPoints[0],Transforms[0]),Transforms[1]));
   end;
   else begin
    result:=0.0;
    Assert(false);
   end;
  end;
 end;
 function FindMinSeparation:TKraftScalar; {$ifdef caninline}inline;{$endif}
 begin
  case SeparationFunctionMode of
   sfmVERTICES:begin
    WitnessPoints[0]:=Shapes[0].GetLocalFeatureSupportVertex(Shapes[0].GetLocalFeatureSupportIndex(Vector3TermMatrixMulTransposedBasis(Axis,Transforms[0])));
    WitnessPoints[1]:=Shapes[1].GetLocalFeatureSupportVertex(Shapes[1].GetLocalFeatureSupportIndex(Vector3TermMatrixMulTransposedBasis(Vector3Neg(Axis),Transforms[1])));
   end;
   sfmEDGEA,sfmFACEA,sfmEDGES:begin
    WitnessPoints[1]:=Shapes[1].GetLocalFeatureSupportVertex(Shapes[1].GetLocalFeatureSupportIndex(Vector3Neg(Vector3TermMatrixMulTransposedBasis(Vector3TermMatrixMulBasis(Axis,Transforms[0]),Transforms[1]))));
   end;
   sfmEDGEB,sfmFACEB:begin
    WitnessPoints[0]:=Shapes[0].GetLocalFeatureSupportVertex(Shapes[0].GetLocalFeatureSupportIndex(Vector3Neg(Vector3TermMatrixMulTransposedBasis(Vector3TermMatrixMulBasis(Axis,Transforms[1]),Transforms[0]))));
   end;
  end;
  result:=Evaluate;
 end;
begin

 result:=false;

 Shapes[0]:=ShapeA;

 if (ShapeBTriangleIndex>=0) and (ShapeB is TKraftShapeMesh) then begin
  MeshShape:=TKraftShapeMesh(ShapeB);
  ShapeTriangle:=TKraftShapeTriangle(TriangleShapes[ThreadIndex]);
  Shapes[1]:=ShapeTriangle;
  MeshTriangle:=@MeshShape.Mesh.Triangles[ShapeBTriangleIndex];
  ShapeTriangle.LocalTransform:=MeshShape.LocalTransform;
  ShapeTriangle.WorldTransform:=MeshShape.WorldTransform;
  ShapeTriangle.ConvexHull.Vertices[0].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[0]];
  ShapeTriangle.ConvexHull.Vertices[1].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[1]];
  ShapeTriangle.ConvexHull.Vertices[2].Position:=MeshShape.Mesh.Vertices[MeshTriangle^.Vertices[2]];
  ShapeTriangle.UpdateData;
 end else begin
  Shapes[1]:=ShapeB;
 end;

 ContinuousMinimumRadiusScaleFactor:=Max(ShapeA.ContinuousMinimumRadiusScaleFactor,ShapeB.ContinuousMinimumRadiusScaleFactor);
 if (ContinuousMinimumRadiusScaleFactor>EPSILON) and
    (Vector3Length(Vector3Sub(Vector3Sub(SweepB.c0,SweepB.c),Vector3Sub(SweepA.c0,SweepA.c)))<Max(EPSILON,Min(Shapes[0].ShapeSphere.Radius,Shapes[1].ShapeSphere.Radius)*ContinuousMinimumRadiusScaleFactor)) then begin
  exit;
 end;

 TotalRadius:=Shapes[0].FeatureRadius+Shapes[1].FeatureRadius;

 Target:=Max(LinearSlop,TotalRadius-(3.0*LinearSlop));

 Tolerance:=LinearSlop*0.25;

 GJK.CachedSimplex:=nil;
 GJK.Shapes[0]:=Shapes[0];
 GJK.Shapes[1]:=Shapes[1];
 GJK.Transforms[0]:=@Transforms[0];
 GJK.Transforms[1]:=@Transforms[1];
 GJK.UseRadii:=false;

 // Compute current closest features. Setup a separation function to evaluate
 // overlap on the axis between the closest features. Terminate if closest
 // features are repeated.

 t0:=0.0;

 Axis:=Vector3Origin;

 SeparationFunctionMode:=sfmNONE;

 for Iteration:=1 to TimeOfImpactMaximumIterations do begin

  Transforms[0]:=Matrix4x4TermMul(Shapes[0].LocalTransform,SweepTransform(SweepA,t0));
  Transforms[1]:=Matrix4x4TermMul(Shapes[1].LocalTransform,SweepTransform(SweepB,t0));

  if not GJK.Run then begin
   Beta:=0.0;
   result:=false;
   exit;
  end;

  // TOI is not defined if shapes began in an overlapping configuration
  if GJK.Distance<EPSILON then begin
   Beta:=0.0;
   result:=false;
   exit;
  end;

  // Check for initial convergent state
  if GJK.Distance<(Target+Tolerance) then begin
   Beta:=t0;
   result:=true;
   exit;
  end;
                        
  // Extract features from GJK
  case GJK.Simplex.Count of
   1:begin

    // GJK point simplex

    UniqueGJKVertexIndices[0,0]:=GJK.Simplex.Vertices[0]^.iA;
    UniqueGJKVertexIndices[1,0]:=GJK.Simplex.Vertices[0]^.iB;
    CountUniqueGJKVertices[0]:=1;
    CountUniqueGJKVertices[1]:=1;

   end;
   2:begin

    // GJK line simplex

    UniqueGJKVertexIndices[0,0]:=GJK.Simplex.Vertices[0]^.iA;
    UniqueGJKVertexIndices[0,1]:=GJK.Simplex.Vertices[1]^.iA;
    if UniqueGJKVertexIndices[0,0]<>UniqueGJKVertexIndices[0,1] then begin
     CountUniqueGJKVertices[0]:=2;
    end else begin
     CountUniqueGJKVertices[0]:=1;
    end;

    UniqueGJKVertexIndices[1,0]:=GJK.Simplex.Vertices[0]^.iB;
    UniqueGJKVertexIndices[1,1]:=GJK.Simplex.Vertices[1]^.iB;
    if UniqueGJKVertexIndices[1,0]<>UniqueGJKVertexIndices[1,1] then begin
     CountUniqueGJKVertices[1]:=2;
    end else begin
     CountUniqueGJKVertices[1]:=1;
    end;

   end;
   3:begin

    // GJK triangle simplex

    UniqueGJKVertexIndices[0,0]:=GJK.Simplex.Vertices[0]^.iA;
    if UniqueGJKVertexIndices[0,0]<>GJK.Simplex.Vertices[1]^.iA then begin
     UniqueGJKVertexIndices[0,1]:=GJK.Simplex.Vertices[1]^.iA;
     if UniqueGJKVertexIndices[0,1]<>GJK.Simplex.Vertices[2]^.iA then begin
      UniqueGJKVertexIndices[0,2]:=GJK.Simplex.Vertices[2]^.iA;
      CountUniqueGJKVertices[0]:=3;
     end else begin
      CountUniqueGJKVertices[0]:=2;
     end;
    end else if UniqueGJKVertexIndices[0,0]<>GJK.Simplex.Vertices[2]^.iA then begin
     UniqueGJKVertexIndices[0,1]:=GJK.Simplex.Vertices[2]^.iA;
     CountUniqueGJKVertices[0]:=2;
    end else begin
     CountUniqueGJKVertices[0]:=1;
    end;

    UniqueGJKVertexIndices[1,0]:=GJK.Simplex.Vertices[0]^.iB;
    if UniqueGJKVertexIndices[1,0]<>GJK.Simplex.Vertices[1]^.iB then begin
     UniqueGJKVertexIndices[1,1]:=GJK.Simplex.Vertices[1]^.iB;
     if UniqueGJKVertexIndices[1,1]<>GJK.Simplex.Vertices[2]^.iB then begin
      UniqueGJKVertexIndices[1,2]:=GJK.Simplex.Vertices[2]^.iB;
      CountUniqueGJKVertices[1]:=3;
     end else begin
      CountUniqueGJKVertices[1]:=2;
     end;
    end else if UniqueGJKVertexIndices[1,0]<>GJK.Simplex.Vertices[2]^.iB then begin
     UniqueGJKVertexIndices[1,1]:=GJK.Simplex.Vertices[2]^.iB;
     CountUniqueGJKVertices[1]:=2;
    end else begin
     CountUniqueGJKVertices[1]:=1;
    end;

   end;
   4:begin
    // GJK tetrahedron simplex, which contains the origin, which means that there is a overlapping configuration, where
    // the time of impact is not defined if shapes are already in an overlapping configuration
    Beta:=0.0;
    result:=false;
    exit;
   end;
   else begin
    // This might happen if the GJK implementation is faulty.
   end;
  end;

  // Initialize the found features for the separation function
  case CountUniqueGJKVertices[0] of
   1:begin
    // Vertex on A
    case CountUniqueGJKVertices[1] of
     1:begin
      // Vertex on A and vertex on B
      Axis:=Vector3NormEx(Vector3Sub(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]),
                                             Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0])));
      SeparationFunctionMode:=sfmVERTICES;
     end;
     2:begin
      // Vertex on A and edge on B
      UniqueGJKVertices[0,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]),Transforms[0]),Transforms[1]);
      UniqueGJKVertices[1,0]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]);
      UniqueGJKVertices[1,1]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,1]);
      Axis:=Vector3Sub(UniqueGJKVertices[1,1],UniqueGJKVertices[1,0]);
      LocalPlane.Normal:=Vector3NormEx(Vector3Cross(Vector3Cross(Axis,Vector3Sub(UniqueGJKVertices[0,0],UniqueGJKVertices[1,0])),Axis));
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[1,0]);
      SeparationFunctionMode:=sfmEDGEB;
     end;
     3:begin
      // Vertex on A and face on B
      UniqueGJKVertices[0,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]),Transforms[0]),Transforms[1]);
      UniqueGJKVertices[1,0]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]);
      UniqueGJKVertices[1,1]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,1]);
      UniqueGJKVertices[1,2]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,2]);
      Axis:=Vector3NormEx(Vector3Cross(Vector3Sub(UniqueGJKVertices[1,0],UniqueGJKVertices[1,1]),Vector3Sub(UniqueGJKVertices[1,2],UniqueGJKVertices[1,1])));
      if Vector3Dot(UniqueGJKVertices[0,0],Axis)<0.0 then begin
       Axis:=Vector3Neg(Axis);
      end;
      LocalPlane.Normal:=Axis;
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[1,0]);
      SeparationFunctionMode:=sfmFACEB;
     end;
    end;
   end;
   2:begin
    // Edge A
    case CountUniqueGJKVertices[1] of
     1:begin
      // Edge on A and vertex on B
      UniqueGJKVertices[0,0]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]);
      UniqueGJKVertices[0,1]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,1]);
      UniqueGJKVertices[1,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]),Transforms[1]),Transforms[0]);
      Axis:=Vector3Sub(UniqueGJKVertices[0,1],UniqueGJKVertices[0,0]);
      LocalPlane.Normal:=Vector3NormEx(Vector3Cross(Vector3Cross(Axis,Vector3Sub(UniqueGJKVertices[1,0],UniqueGJKVertices[0,0])),Axis));
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[0,0]);
      SeparationFunctionMode:=sfmEDGEA;
     end;
     2:begin
      // Edge on A and edge on B
      UniqueGJKVertices[0,0]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]);
      UniqueGJKVertices[0,1]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,1]);
      UniqueGJKVertices[1,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]),Transforms[1]),Transforms[0]);
      UniqueGJKVertices[1,1]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,1]),Transforms[1]),Transforms[0]);
      eA:=Vector3Sub(UniqueGJKVertices[0,1],UniqueGJKVertices[0,0]);
      eB:=Vector3Sub(UniqueGJKVertices[1,1],UniqueGJKVertices[1,0]);
      Axis:=Vector3NormEx(Vector3Cross(eA,eB));
      if Vector3Dot(Vector3Sub(eB,eA),Axis)<0.0 then begin
       Axis:=Vector3Neg(Axis);
      end;
      LocalPlane.Normal:=Axis;
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,eA);
      SeparationFunctionMode:=sfmEDGES;
     end;
     3:begin
      // Edge on A and face on B
      UniqueGJKVertices[0,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]),Transforms[0]),Transforms[1]);
      UniqueGJKVertices[0,1]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,1]),Transforms[0]),Transforms[1]);
      UniqueGJKVertices[1,0]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]);
      UniqueGJKVertices[1,1]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,1]);
      UniqueGJKVertices[1,2]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,2]);
      Axis:=Vector3NormEx(Vector3Cross(Vector3Sub(UniqueGJKVertices[1,0],UniqueGJKVertices[1,1]),Vector3Sub(UniqueGJKVertices[1,2],UniqueGJKVertices[1,1])));
      if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,0],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,1],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2]) then begin
       if Vector3Dot(UniqueGJKVertices[0,0],Axis)<0.0 then begin
        Axis:=Vector3Neg(Axis);
       end;
      end else begin
       if Vector3Dot(UniqueGJKVertices[0,1],Axis)<0.0 then begin
        Axis:=Vector3Neg(Axis);
       end;
      end;
      LocalPlane.Normal:=Axis;
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[1,0]);
      SeparationFunctionMode:=sfmFACEB;
     end;
    end;
   end;
   3:begin
    // Face on A
    case CountUniqueGJKVertices[1] of
     1:begin
      // Face on A and vertex on B
      UniqueGJKVertices[0,0]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]);
      UniqueGJKVertices[0,1]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,1]);
      UniqueGJKVertices[0,2]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,2]);
      UniqueGJKVertices[1,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]),Transforms[1]),Transforms[0]);
      Axis:=Vector3NormEx(Vector3Cross(Vector3Sub(UniqueGJKVertices[0,0],UniqueGJKVertices[0,1]),Vector3Sub(UniqueGJKVertices[0,2],UniqueGJKVertices[0,1])));
      if Vector3Dot(UniqueGJKVertices[1,0],Axis)<0.0 then begin
       Axis:=Vector3Neg(Axis);
      end;
      LocalPlane.Normal:=Axis;
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[0,0]);
      SeparationFunctionMode:=sfmFACEA;
     end;
     2:begin
      // Face on A and edge on B
      UniqueGJKVertices[0,0]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]);
      UniqueGJKVertices[0,1]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,1]);
      UniqueGJKVertices[0,2]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,2]);
      UniqueGJKVertices[1,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]),Transforms[1]),Transforms[0]);
      UniqueGJKVertices[1,1]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,1]),Transforms[1]),Transforms[0]);
      Axis:=Vector3NormEx(Vector3Cross(Vector3Sub(UniqueGJKVertices[0,0],UniqueGJKVertices[0,1]),Vector3Sub(UniqueGJKVertices[0,2],UniqueGJKVertices[0,1])));
      if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,0],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,1],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2]) then begin
       if Vector3Dot(UniqueGJKVertices[1,0],Axis)<0.0 then begin
        Axis:=Vector3Neg(Axis);
       end;
      end else begin
       if Vector3Dot(UniqueGJKVertices[1,1],Axis)<0.0 then begin
        Axis:=Vector3Neg(Axis);
       end;
      end;
      LocalPlane.Normal:=Axis;
      LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[0,0]);
      SeparationFunctionMode:=sfmFACEA;
     end;
     3:begin
      // Face on A and face on B
      UniqueGJKVertices[0,0]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,0]);
      UniqueGJKVertices[0,1]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,1]);
      UniqueGJKVertices[0,2]:=Shapes[0].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[0,2]);
      UniqueGJKVertices[1,0]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,0]);
      UniqueGJKVertices[1,1]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,1]);
      UniqueGJKVertices[1,2]:=Shapes[1].GetLocalFeatureSupportVertex(UniqueGJKVertexIndices[1,2]);
      if CalculateArea(UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2])<CalculateArea(UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2]) then begin
       // Face B has a larger area than face A
       UniqueGJKVertices[0,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(UniqueGJKVertices[0,0],Transforms[0]),Transforms[1]);
       UniqueGJKVertices[0,1]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(UniqueGJKVertices[0,1],Transforms[0]),Transforms[1]);
       UniqueGJKVertices[0,2]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(UniqueGJKVertices[0,2],Transforms[0]),Transforms[1]);
       Axis:=Vector3NormEx(Vector3Cross(Vector3Sub(UniqueGJKVertices[1,0],UniqueGJKVertices[1,1]),Vector3Sub(UniqueGJKVertices[1,2],UniqueGJKVertices[1,1])));
       if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,0],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,1],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2]) then begin
        if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,0],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,2],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2]) then begin
         if Vector3Dot(UniqueGJKVertices[0,0],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end else begin
         if Vector3Dot(UniqueGJKVertices[0,2],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end;
       end else begin
        if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,1],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[0,2],UniqueGJKVertices[1,0],UniqueGJKVertices[1,1],UniqueGJKVertices[1,2]) then begin
         if Vector3Dot(UniqueGJKVertices[0,1],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end else begin
         if Vector3Dot(UniqueGJKVertices[0,2],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end;
       end;
       LocalPlane.Normal:=Axis;
       LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[1,0]);
       SeparationFunctionMode:=sfmFACEB;
      end else begin
       // Face A has a larger area than face B
       UniqueGJKVertices[1,0]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(UniqueGJKVertices[1,0],Transforms[1]),Transforms[0]);
       UniqueGJKVertices[1,1]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(UniqueGJKVertices[1,1],Transforms[1]),Transforms[0]);
       UniqueGJKVertices[1,2]:=Vector3TermMatrixMulInverted(Vector3TermMatrixMul(UniqueGJKVertices[1,2],Transforms[1]),Transforms[0]);
       Axis:=Vector3NormEx(Vector3Cross(Vector3Sub(UniqueGJKVertices[0,0],UniqueGJKVertices[0,1]),Vector3Sub(UniqueGJKVertices[0,2],UniqueGJKVertices[0,1])));
       if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,0],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,1],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2]) then begin
        if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,0],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,2],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2]) then begin
         if Vector3Dot(UniqueGJKVertices[1,0],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end else begin
         if Vector3Dot(UniqueGJKVertices[1,2],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end;
       end else begin
        if SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,1],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2])<SquaredDistanceFromPointToTriangle(UniqueGJKVertices[1,2],UniqueGJKVertices[0,0],UniqueGJKVertices[0,1],UniqueGJKVertices[0,2]) then begin
         if Vector3Dot(UniqueGJKVertices[1,1],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end else begin
         if Vector3Dot(UniqueGJKVertices[1,2],Axis)<0.0 then begin
          Axis:=Vector3Neg(Axis);
         end;
        end;
       end;
       LocalPlane.Normal:=Axis;
       LocalPlane.Distance:=-Vector3Dot(LocalPlane.Normal,UniqueGJKVertices[0,0]);
       SeparationFunctionMode:=sfmFACEA;
      end;
     end;
    end;
   end;
  end;

  // Successively resolve the deepest point to compute the time of impact, loop is bounded by the number of vertices to be resolved.
  t1:=1.0;
  for TryIteration:=1 to 64 do begin

   // Compute deepest witness points at t1
   Transforms[0]:=Matrix4x4TermMul(Shapes[0].LocalTransform,SweepTransform(SweepA,t1));
   Transforms[1]:=Matrix4x4TermMul(Shapes[1].LocalTransform,SweepTransform(SweepB,t1));
   s1:=FindMinSeparation;

   // Is the final configuration separated?
   if s1>(Target+Tolerance) then begin
    exit;
   end;

   // Has the separation reached tolerance?
   if s1>(Target-Tolerance) then begin
    // Advance the sweeps
    t0:=t1;
    if t0>=(1.0-EPSILON) then begin
     exit;
    end else begin
     break;
    end;
   end;

   // Compute the initial separation of the witness points
   Transforms[0]:=Matrix4x4TermMul(Shapes[0].LocalTransform,SweepTransform(SweepA,t0));
   Transforms[1]:=Matrix4x4TermMul(Shapes[1].LocalTransform,SweepTransform(SweepB,t0));
   s0:=Evaluate;

   // Check for initial overlap
   if s0<(Target-Tolerance) then begin
    // This might happen if the root finder runs out of iterations. Also more likely to happen with a poor separation function.
    Beta:=t0;
    result:=false;
    exit;
   end;

   // Check for touching, t0 should hold the time of impact (could be 0.0)
   if s0<=(Target+Tolerance) then begin
    Beta:=t0;
    result:=true;
    exit;
   end;

   // Compute the 1D root of: f(x)-Target=0
   a0:=t0;
   a1:=t1;
   for RootIteration:=0 to 63 do begin

    if (RootIteration and 1)<>0 then begin
     t:=a1+((Target-s0)*((a1-a0)/(s1-s0)));
    end else begin
     t:=(a0+a1)*0.5;
    end;

    Transforms[0]:=Matrix4x4TermMul(Shapes[0].LocalTransform,SweepTransform(SweepA,t));
    Transforms[1]:=Matrix4x4TermMul(Shapes[1].LocalTransform,SweepTransform(SweepB,t));
    s:=Evaluate;

    if abs(s-Target)<Tolerance then begin
     // t1 holds a tentative value for t0
     t1:=t;
     break;
    end else if s>Target then begin
     a0:=t;
     s0:=s;
    end else begin
     a1:=t;
     s1:=s;
    end;

   end;

  end;

 end;

end;

function TKraft.GetTimeOfImpact(const ShapeA:TKraftShape;const SweepA:TKraftSweep;const ShapeB:TKraftShape;const ShapeBTriangleIndex:longint;const SweepB:TKraftSweep;const TimeStep:TKraftTimeStep;const ThreadIndex:longint;var Beta:TKraftScalar):boolean;
begin
 case TimeOfImpactAlgorithm of
  ktoiaConservativeAdvancement:begin
   result:=GetConservativeAdvancementTimeOfImpact(ShapeA,SweepA,ShapeB,ShapeBTriangleIndex,SweepB,TimeStep,ThreadIndex,Beta);
  end;
  else {ktoiaBilateralAdvancement:}begin
   result:=GetBilateralAdvancementTimeOfImpact(ShapeA,SweepA,ShapeB,ShapeBTriangleIndex,SweepB,TimeStep,ThreadIndex,Beta);
  end;
 end;
end;

procedure TKraft.Solve(const TimeStep:TKraftTimeStep);
var RigidBody:TKraftRigidBody;
begin

 BuildIslands;

 SolveIslands(TimeStep);

 RigidBody:=DynamicRigidBodyFirst;
 while assigned(RigidBody) do begin
  RigidBody.SynchronizeProxies;
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 RigidBody:=KinematicRigidBodyFirst;
 while assigned(RigidBody) do begin
  RigidBody.SynchronizeProxies;
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 ContactManager.CountMeshTriangleContactQueueItems:=0;

 ContactManager.DoBroadPhase;

 ContactManager.DoMidPhase;

end;

procedure TKraft.SolveContinuousMotionClamping(const TimeStep:TKraftTimeStep);
var RigidBody:TKraftRigidBody;
    ContactPair:PKraftContactPair;
    Beta:TKraftScalar;
    NeedUpdate:boolean;
    ContactPairEdge:PKraftContactPairEdge;
    RigidBodies:array[0..1] of TKraftRigidBody;
    Sweeps:array[0..1] of TKraftSweep;
begin

 NeedUpdate:=false;

 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  RigidBody.Sweep.Alpha0:=0.0;
  RigidBody.TimeOfImpact:=1.0;
  RigidBody.Island:=nil;
  RigidBody.Flags:=RigidBody.Flags-[krbfIslandVisited,krbfIslandStatic];
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 ContactPair:=ContactManager.ContactPairFirst;
 while assigned(ContactPair) do begin
  ContactPair^.Island:=nil;
  ContactPair^.Flags:=ContactPair^.Flags-[kcfInIsland,kcfTimeOfImpact];
  ContactPair^.TimeOfImpactCount:=0;
  ContactPair^.TimeOfImpact:=1.0;
  ContactPair:=ContactPair.Next;
 end;

 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  if RigidBody.RigidBodyType=krbtDynamic then begin
   ContactPairEdge:=RigidBody.ContactPairEdgeFirst;
   while assigned(ContactPairEdge) do begin
    ContactPair:=ContactPairEdge^.ContactPair;
    if (not (kcfInIsland in ContactPair^.Flags)) and
       (((RigidBody.Flags*[krbfAwake,krbfActive])=[krbfAwake,krbfActive]) or
        ((ContactPairEdge^.OtherRigidBody.Flags*[krbfAwake,krbfActive])=[krbfAwake,krbfActive])) and
       (not (((ksfSensor in ContactPair^.Shapes[0].Flags) or
              (ksfSensor in ContactPair^.Shapes[1].Flags)) or
             ((krbfSensor in RigidBody.Flags) or
              (krbfSensor in ContactPairEdge^.OtherRigidBody.Flags)))) and
       (not (((RigidBody.RigidBodyType=krbtDynamic) and (ContactPairEdge^.OtherRigidBody.RigidBodyType=krbtDynamic)) and not
             (ContactManager.Physics.ContinuousAgainstDynamics and
              ((krbfContinuousAgainstDynamics in RigidBody.Flags) or
               (krbfContinuousAgainstDynamics in ContactPairEdge^.OtherRigidBody.Flags)
              )
             )
            )
       ) then begin
     ContactPair^.Flags:=ContactPair^.Flags+[kcfInIsland];
     if not (kcfColliding in ContactPair^.Flags) then begin
      RigidBodies[0]:=ContactPair^.Shapes[0].RigidBody;
      RigidBodies[1]:=ContactPair^.Shapes[1].RigidBody;
      if assigned(RigidBodies[0]) and assigned(RigidBodies[1]) then begin
       Sweeps[0]:=SweepTermNormalize(RigidBodies[0].Sweep);
       Sweeps[1]:=SweepTermNormalize(RigidBodies[1].Sweep);
       if GetTimeOfImpact(ContactPair^.Shapes[0],
                          Sweeps[0],
                          ContactPair^.Shapes[1],
                          ContactPair^.ElementIndex,
                          Sweeps[1],
                          TimeStep,
                          0,
                          Beta) then begin
        // Check for that the object will not get stucking, when it is alreading colliding at beginning
        if Beta>0.0 then begin
         RigidBodies[0].TimeOfImpact:=Min(RigidBodies[0].TimeOfImpact,Beta);
         RigidBodies[1].TimeOfImpact:=Min(RigidBodies[1].TimeOfImpact,Beta);
        end;
       end;
      end;
     end;
    end;
    ContactPairEdge:=ContactPairEdge^.Next;
   end;
  end;
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  if (RigidBody.RigidBodyType=krbtDynamic) and ({(RigidBody.TimeOfImpact>0.0) and} (RigidBody.TimeOfImpact<1.0)) then begin
// writeln(RigidBody.TimeOfImpact:1:8);
   RigidBody.Advance(RigidBody.TimeOfImpact);
   RigidBody.SynchronizeProxies;
   NeedUpdate:=true;
  end;
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 if NeedUpdate then begin
  ContactManager.CountMeshTriangleContactQueueItems:=0;
  ContactManager.DoBroadPhase;
  ContactManager.DoMidPhase;
  ContactManager.DoNarrowPhase;
 end;

end;

procedure TKraft.SolveContinuousTimeOfImpactSubSteps(const TimeStep:TKraftTimeStep);
const FLAG_VISITED=1 shl 0;
      FLAG_STATIC=1 shl 1;
var TryIndex,Index,SubIndex,LastCount,Count,IndexA,IndexB{,c{}:longint;
    NeedUpdate:boolean;
    RigidBody,CurrentRigidBody,OtherRigidBody:TKraftRigidBody;
    ContactPair,MinimumContactPair:PKraftContactPair;
    MinimumAlpha,Alpha,Alpha0,Beta:TKraftScalar;
    Island:TKraftIsland;
    ContactPairEdge:PKraftContactPairEdge;
    RigidBodies:array[0..1] of TKraftRigidBody;
    BackupSweeps:array[0..1] of TKraftSweep;
    SubTimeStep:TKraftTimeStep;
begin

 NeedUpdate:=false;

 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  RigidBody.Sweep.Alpha0:=0.0;
  RigidBody.Island:=nil;
  RigidBody.Flags:=RigidBody.Flags-[krbfIslandVisited,krbfIslandStatic];
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 Count:=0;
 ContactPair:=ContactManager.ContactPairFirst;
 while assigned(ContactPair) do begin
  ContactPair^.Island:=nil;
  ContactPair^.Flags:=ContactPair^.Flags-[kcfInIsland,kcfTimeOfImpact];
  ContactPair^.TimeOfImpactCount:=0;
  ContactPair^.TimeOfImpact:=1.0;
  inc(Count);
  ContactPair:=ContactPair.Next;
 end;

 for TryIndex:=1 to Count do begin

  MinimumContactPair:=nil;
  MinimumAlpha:=1.0;

//c:=0;

  ContactPair:=ContactManager.ContactPairFirst;
  while assigned(ContactPair) do begin

   if (ContactPair^.TimeOfImpactCount>=MaximalSubSteps) or not (kcfEnabled in ContactPair^.Flags) then begin
    ContactPair:=ContactPair^.Next;
    continue;
   end;

   if kcfTimeOfImpact in ContactPair^.Flags then begin

    Alpha:=ContactPair^.TimeOfImpact;

   end else begin

    Alpha:=1.0;

    if (ksfSensor in ContactPair^.Shapes[0].Flags) or
       (ksfSensor in ContactPair^.Shapes[1].Flags) then begin
     ContactPair:=ContactPair^.Next;
     continue;
    end;

    RigidBodies[0]:=ContactPair^.Shapes[0].RigidBody;
    RigidBodies[1]:=ContactPair^.Shapes[1].RigidBody;

    if not ((assigned(RigidBodies[0]) and assigned(RigidBodies[1])) and
            (((RigidBodies[0].RigidBodyType=krbtDynamic) or (RigidBodies[1].RigidBodyType=krbtDynamic)) and
             (((RigidBodies[0].Flags*[krbfAwake,krbfActive])=[krbfAwake,krbfActive]) or
              ((RigidBodies[1].Flags*[krbfAwake,krbfActive])=[krbfAwake,krbfActive])) and
             ((krbfContinuous in RigidBodies[0].Flags) and (krbfContinuous in RigidBodies[1].Flags)))) then begin
     ContactPair:=ContactPair^.Next;
     continue;
    end;

    if ((krbfSensor in ContactPair^.RigidBodies[0].Flags) or
        (krbfSensor in ContactPair^.RigidBodies[1].Flags)) or
       (((RigidBodies[0].RigidBodyType=krbtDynamic) and (RigidBodies[1].RigidBodyType=krbtDynamic)) and not
        (ContinuousAgainstDynamics and
         ((krbfContinuousAgainstDynamics in RigidBodies[0].Flags) or
          (krbfContinuousAgainstDynamics in RigidBodies[1].Flags)))) then begin
     ContactPair:=ContactPair^.Next;
     continue;
    end;

{   if (Vector3Length(RigidBodies[0].LinearVelocity)<EPSILON) and
       (Vector3Length(RigidBodies[0].AngularVelocity)<EPSILON) and
       (Vector3Length(RigidBodies[1].LinearVelocity)<EPSILON) and
       (Vector3Length(RigidBodies[1].AngularVelocity)<EPSILON) then begin
     ContactPair:=ContactPair^.Next;
     continue;
    end;{}

    // Compute TOI for this elligable contact and place sweeps onto the same time interval
    if RigidBodies[0].Sweep.Alpha0<RigidBodies[1].Sweep.Alpha0 then begin
     Alpha0:=RigidBodies[1].Sweep.Alpha0;
     SweepAdvance(RigidBodies[0].Sweep,Alpha0);
    end else if RigidBodies[1].Sweep.Alpha0<RigidBodies[0].Sweep.Alpha0 then begin
     Alpha0:=RigidBodies[0].Sweep.Alpha0;
     SweepAdvance(RigidBodies[1].Sweep,Alpha0);
    end else begin
     Alpha0:=RigidBodies[0].Sweep.Alpha0;
    end;

    Assert(Alpha0<1.0);

    Beta:=0.0;
    if GetTimeOfImpact(ContactPair^.Shapes[0],
                       SweepTermNormalize(RigidBodies[0].Sweep),
                       ContactPair^.Shapes[1],
                       ContactPair^.ElementIndex,
                       SweepTermNormalize(RigidBodies[1].Sweep),
                       TimeStep,
                       0,
                       Beta) then begin
     Alpha:=Min(Alpha0+((1.0-Alpha0)*Beta),1.0);
    end;

    ContactPair^.TimeOfImpact:=Alpha;
    ContactPair^.Flags:=ContactPair^.Flags+[kcfTimeOfImpact];

   end;

   if MinimumAlpha>Alpha then begin
    MinimumAlpha:=Alpha;
    MinimumContactPair:=ContactPair;
   end;

// inc(c);
   ContactPair:=ContactPair^.Next;

  end;

  // End loop if no minimum contact exists (all have been processed, if any existed) or if time is almost exhausted
  if (not assigned(MinimumContactPair)) or ((1.0-EPSILON)<MinimumAlpha) then begin
   break;
  end;

{ if c>=0 then begin
   writeln(TryIndex:4,' ',c:4,' ',MinimumAlpha:1:8);
  end;{}

  RigidBodies[0]:=MinimumContactPair^.Shapes[0].RigidBody;
  RigidBodies[1]:=MinimumContactPair^.Shapes[1].RigidBody;

  BackupSweeps[0]:=RigidBodies[0].Sweep;
  BackupSweeps[1]:=RigidBodies[1].Sweep;

  RigidBodies[0].Advance(MinimumAlpha);
  RigidBodies[1].Advance(MinimumAlpha);

  MinimumContactPair^.DetectCollisions(ContactManager,TriangleShapes[0],0);

  MinimumContactPair^.Flags:=MinimumContactPair^.Flags-[kcfTimeOfImpact];
  inc(MinimumContactPair^.TimeOfImpactCount);

  if (not (kcfColliding in MinimumContactPair^.Flags)) or not (kcfEnabled in MinimumContactPair^.Flags) then begin
   MinimumContactPair^.Flags:=MinimumContactPair^.Flags-[kcfEnabled];
   RigidBodies[0].Sweep:=BackupSweeps[0];
   RigidBodies[1].Sweep:=BackupSweeps[1];
   RigidBodies[0].SynchronizeTransformIncludingShapes;
   RigidBodies[1].SynchronizeTransformIncludingShapes;
   continue;
  end;

  RigidBodies[0].SetToAwake;
  RigidBodies[1].SetToAwake;

  if length(Islands)<1 then begin
   LastCount:=length(Islands);
   SetLength(Islands,2);
   for SubIndex:=LastCount to length(Islands)-1 do begin
    Islands[SubIndex]:=TKraftIsland.Create(self,SubIndex);
   end;
  end;

  CurrentRigidBody:=RigidBodyFirst;
  while assigned(CurrentRigidBody) do begin
   CurrentRigidBody.Island:=nil;
   CurrentRigidBody.Flags:=CurrentRigidBody.Flags-[krbfIslandVisited,krbfIslandStatic];
   CurrentRigidBody:=CurrentRigidBody.RigidBodyNext;
  end;

  Island:=Islands[0];
  Island.Clear;
  IndexA:=Island.AddRigidBody(RigidBodies[0]);
  IndexB:=Island.AddRigidBody(RigidBodies[1]);
  Island.AddContactPair(MinimumContactPair);

  Include(RigidBodies[0].Flags,krbfIslandVisited);
  Include(RigidBodies[1].Flags,krbfIslandVisited);
  Include(MinimumContactPair^.Flags,kcfInIsland);

  for Index:=0 to 1 do begin

   RigidBody:=RigidBodies[Index];

   if RigidBody.RigidBodyType=krbtDynamic then begin

    ContactPairEdge:=RigidBody.ContactPairEdgeFirst;
    while assigned(ContactPairEdge) do begin
     ContactPair:=ContactPairEdge^.ContactPair;
     OtherRigidBody:=ContactPairEdge^.OtherRigidBody;
     if (not (kcfInIsland in ContactPair^.Flags)) and not
        ((((ksfSensor in ContactPair^.Shapes[0].Flags) or
           (ksfSensor in ContactPair^.Shapes[1].Flags)) or
          ((krbfSensor in RigidBody.Flags) or
           (krbfSensor in OtherRigidBody.Flags))) or
         ((OtherRigidBody.RigidBodyType=krbtDynamic) and not
          (ContinuousAgainstDynamics and
           ((krbfContinuousAgainstDynamics in RigidBody.Flags) or
            (krbfContinuousAgainstDynamics in OtherRigidBody.Flags))))) then begin

      BackupSweeps[0]:=OtherRigidBody.Sweep;
      if (not (krbfIslandVisited in OtherRigidBody.Flags)) and not assigned(OtherRigidBody.Island) then begin
       OtherRigidBody.Advance(MinimumAlpha);
      end;

      ContactPair^.DetectCollisions(ContactManager,TriangleShapes[0],0);

      if (not (kcfEnabled in ContactPair^.Flags)) or not (kcfColliding in ContactPair^.Flags) then begin
       OtherRigidBody.Sweep:=BackupSweeps[0];
       OtherRigidBody.SynchronizeTransformIncludingShapes;
      end else begin

       Island.AddContactPair(ContactPair);
       ContactPair^.Flags:=ContactPair^.Flags+[kcfInIsland];

       if (krbfIslandVisited in OtherRigidBody.Flags) or assigned(OtherRigidBody.Island) then begin
        Island.AddRigidBody(OtherRigidBody);
        Include(OtherRigidBody.Flags,krbfIslandVisited);
        if OtherRigidBody.RigidBodyType<>krbtStatic then begin
         OtherRigidBody.SetToAwake;
        end;
       end;

      end;

     end;
     ContactPairEdge:=ContactPairEdge^.Next;
    end;

   end;

  end;

  Island.MergeContactPairs;

  SubTimeStep.DeltaTime:=(1.0-MinimumAlpha)*TimeStep.DeltaTime;
  SubTimeStep.InverseDeltaTime:=1.0/SubTimeStep.DeltaTime;
  SubTimeStep.DeltaTimeRatio:=1.0;
  SubTimeStep.WarmStarting:=false;
  Island.SolveTimeOfImpact(SubTimeStep,IndexA,IndexB);

  for Index:=0 to Island.CountRigidBodies-1 do begin
   RigidBody:=Island.RigidBodies[Index];
   RigidBody.Island:=nil;
   RigidBody.Flags:=RigidBody.Flags-[krbfIslandVisited,krbfIslandStatic];
   if RigidBody.RigidBodyType=krbtDynamic then begin
    RigidBody.SynchronizeProxies;
    ContactPairEdge:=RigidBody.ContactPairEdgeFirst;
    while assigned(ContactPairEdge) do begin
     ContactPair:=ContactPairEdge^.ContactPair;
     ContactPair^.Flags:=ContactPair^.Flags-[kcfInIsland,kcfTimeOfImpact];
     ContactPairEdge:=ContactPairEdge^.Next;
    end;
   end;
  end;

  ContactManager.CountMeshTriangleContactQueueItems:=0;
  ContactManager.DoBroadPhase;
  ContactManager.DoMidPhase;
  NeedUpdate:=true;

 end;

 if NeedUpdate then begin
  ContactManager.DoNarrowPhase;
 end;

end;

procedure TKraft.StoreWorldTransforms;
var RigidBody:TKraftRigidBody;
begin
 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  RigidBody.StoreWorldTransform;
  RigidBody:=RigidBody.RigidBodyNext;
 end;
end;

procedure TKraft.InterpolateWorldTransforms(const Alpha:TKraftScalar);
var RigidBody:TKraftRigidBody;
begin
 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  RigidBody.InterpolateWorldTransform(Alpha);
  RigidBody:=RigidBody.RigidBodyNext;
 end;
end;

procedure TKraft.Step(const ADeltaTime:TKraftScalar=0);
var RigidBody:TKraftRigidBody;
    Constraint,NextConstraint:TKraftConstraint;
    OldFPUPrecisionMode:TFPUPrecisionMode;
    OldFPUExceptionMask:TFPUExceptionMask;
    OldSIMDFlags:longword;
    StartTime:int64;
    TimeStep:TKraftTimeStep;
begin

 BroadPhaseTime:=0;
 MidPhaseTime:=0;
 NarrowPhaseTime:=0;
 SolverTime:=0;
 ContinuousTime:=0;
 TotalTime:=HighResolutionTimer.GetTime;

 if abs(ADeltaTime)<EPSILON then begin
  TimeStep.DeltaTime:=WorldDeltaTime;
 end else begin
  TimeStep.DeltaTime:=ADeltaTime;
 end;
 if IsZero(TimeStep.DeltaTime) then begin
  TimeStep.InverseDeltaTime:=1.0;
 end else begin
  TimeStep.InverseDeltaTime:=1.0/TimeStep.DeltaTime;
 end;
 TimeStep.DeltaTimeRatio:=LastInverseDeltaTime*TimeStep.DeltaTime;
 TimeStep.WarmStarting:=WarmStarting;

{$ifdef DebugDraw}
 ContactManager.CountDebugConvexHullVertexLists:=0;
{$endif}

 OldFPUPrecisionMode:=GetPrecisionMode;
 if OldFPUPrecisionMode<>PhysicsFPUPrecisionMode then begin
  SetPrecisionMode(PhysicsFPUPrecisionMode);
 end;

 OldFPUExceptionMask:=GetExceptionMask;
 if OldFPUExceptionMask<>PhysicsFPUExceptionMask then begin
  SetExceptionMask(PhysicsFPUExceptionMask);
 end;

 OldSIMDFlags:=SIMDGetFlags;

 SIMDSetOurFlags;

 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  if assigned(RigidBody.OnPreStep) then begin
   RigidBody.OnPreStep(RigidBody,TimeStep);
  end;
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 if NewShapes then begin
  NewShapes:=false;
  ContactManager.DoBroadPhase;
  ContactManager.DoMidPhase;
 end;

 ContactManager.DoNarrowPhase;

 StartTime:=HighResolutionTimer.GetTime;
 Solve(TimeStep);
 inc(SolverTime,HighResolutionTimer.GetTime-StartTime);

 case ContactManager.Physics.ContinuousMode of
  kcmMotionClamping:begin
   StartTime:=HighResolutionTimer.GetTime;
   SolveContinuousMotionClamping(TimeStep);
   inc(ContinuousTime,HighResolutionTimer.GetTime-StartTime);
  end;
  kcmTimeOfImpactSubSteps:begin
   StartTime:=HighResolutionTimer.GetTime;
   SolveContinuousTimeOfImpactSubSteps(TimeStep);
   inc(ContinuousTime,HighResolutionTimer.GetTime-StartTime);
  end;
 end;

 Constraint:=ConstraintFirst;
 while assigned(Constraint) do begin
  NextConstraint:=Constraint.Next;
  if kcfFreshBreaked in Constraint.Flags then begin
   Exclude(Constraint.Flags,kcfFreshBreaked);
   if assigned(Constraint.OnBreak) then begin
    Constraint.OnBreak(self,Constraint);
   end;
  end;
  Constraint:=NextConstraint;
 end;

 RigidBody:=RigidBodyFirst;
 while assigned(RigidBody) do begin
  if RigidBody.RigidBodyType<>krbtSTATIC then begin
   RigidBody.Force:=Vector3Origin;
   RigidBody.Torque:=Vector3Origin;
  end;
  if assigned(RigidBody.OnPostStep) then begin
   RigidBody.OnPostStep(RigidBody,TimeStep);
  end;
  RigidBody:=RigidBody.RigidBodyNext;
 end;

 if TimeStep.DeltaTime>0.0 then begin
  LastInverseDeltaTime:=TimeStep.InverseDeltaTime;
 end;

 SIMDSetFlags(OldSIMDFlags);

 if OldFPUExceptionMask<>PhysicsFPUExceptionMask then begin
  SetExceptionMask(OldFPUExceptionMask);
 end;

 if OldFPUPrecisionMode<>PhysicsFPUPrecisionMode then begin
  SetPrecisionMode(OldFPUPrecisionMode);
 end;

 TotalTime:=HighResolutionTimer.GetTime-TotalTime;

end;

function TKraft.TestPoint(const Point:TKraftVector3):TKraftShape;
var Hit:TKraftShape;
 procedure QueryTree(AABBTree:TKraftDynamicAABBTree);
 var LocalStack:PKraftDynamicAABBTreeLongintArray;
     LocalStackPointer,NodeID:longint;
     Node:PKraftDynamicAABBTreeNode;
     CurrentShape:TKraftShape;
 begin
  if assigned(AABBTree) then begin
   if AABBTree.Root>=0 then begin
    LocalStack:=AABBTree.Stack;
    LocalStack^[0]:=AABBTree.Root;
    LocalStackPointer:=1;
    while LocalStackPointer>0 do begin
     dec(LocalStackPointer);
     NodeID:=LocalStack^[LocalStackPointer];
     if NodeID>=0 then begin
      Node:=@AABBTree.Nodes[NodeID];
      if AABBContains(Node^.AABB,Point) then begin
       if Node^.Children[0]<0 then begin
        CurrentShape:=Node^.UserData;
        if assigned(CurrentShape) and CurrentShape.TestPoint(Point) then begin
         Hit:=CurrentShape;
         exit;
        end;
       end else begin
        if AABBTree.StackCapacity<=(LocalStackPointer+2) then begin
         AABBTree.StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+2);
         ReallocMem(AABBTree.Stack,AABBTree.StackCapacity*SizeOf(longint));
         LocalStack:=AABBTree.Stack;
        end;
        LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
        LocalStack^[LocalStackPointer+1]:=Node^.Children[1];
        inc(LocalStackPointer,2);
       end;
      end;
     end;
    end;
   end;
  end;
 end;
begin
 Hit:=nil;
 QueryTree(StaticAABBTree);
 if not assigned(Hit) then begin
  QueryTree(SleepingAABBTree);
 end;
 if not assigned(Hit) then begin
  QueryTree(DynamicAABBTree);
 end;
 if not assigned(Hit) then begin
  QueryTree(KinematicAABBTree);
 end;
 result:=Hit;
end;

function TKraft.RayCast(const Origin,Direction:TKraftVector3;const MaxTime:TKraftScalar;var Shape:TKraftShape;var Time:TKraftScalar;var Point,Normal:TKraftVector3;const CollisionGroups:TKraftRigidBodyCollisionGroups=[low(TKraftRigidBodyCollisionGroup)..high(TKraftRigidBodyCollisionGroup)]):boolean;
var Hit:longbool;
 procedure QueryTree(AABBTree:TKraftDynamicAABBTree);
 var LocalStack:PKraftDynamicAABBTreeLongintArray;
     LocalStackPointer,NodeID:longint;
     Node:PKraftDynamicAABBTreeNode;
     CurrentShape:TKraftShape;
     RayCastData:TKraftRaycastData;
 begin
  if assigned(AABBTree) then begin
   if AABBTree.Root>=0 then begin
    LocalStack:=AABBTree.Stack;
    LocalStack^[0]:=AABBTree.Root;
    LocalStackPointer:=1;
    while LocalStackPointer>0 do begin
     dec(LocalStackPointer);
     NodeID:=LocalStack^[LocalStackPointer];
     if NodeID>=0 then begin
      Node:=@AABBTree.Nodes[NodeID];
      if AABBRayIntersect(Node^.AABB,Origin,Direction) then begin
       if Node^.Children[0]<0 then begin
        CurrentShape:=Node^.UserData;
        RayCastData.Origin:=Origin;
        RayCastData.Direction:=Direction;
        RayCastData.MaxTime:=MaxTime;
        if (assigned(CurrentShape) and (assigned(CurrentShape.RigidBody) and ((CurrentShape.RigidBody.CollisionGroups*CollisionGroups)<>[]))) and CurrentShape.RayCast(RayCastData) then begin
         if (Hit and (RayCastData.TimeOfImpact<Time)) or not Hit then begin
          Hit:=true;
          Time:=RayCastData.TimeOfImpact;
          Point:=RayCastData.Point;
          Normal:=RayCastData.Normal;
          Shape:=CurrentShape;
         end;
        end;
       end else begin
        if AABBTree.StackCapacity<=(LocalStackPointer+2) then begin
         AABBTree.StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+2);
         ReallocMem(AABBTree.Stack,AABBTree.StackCapacity*SizeOf(longint));
         LocalStack:=AABBTree.Stack;
        end;
        LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
        LocalStack^[LocalStackPointer+1]:=Node^.Children[1];
        inc(LocalStackPointer,2);
       end;
      end;
     end;
    end;
   end;
  end;
 end;
begin
 Hit:=false;
 Time:=MaxTime;
 QueryTree(StaticAABBTree);
 QueryTree(SleepingAABBTree);
 QueryTree(DynamicAABBTree);
 QueryTree(KinematicAABBTree);
 result:=Hit;
end;

function TKraft.PushSphere(var Center:TKraftVector3;const Radius:TKraftScalar;const CollisionGroups:TKraftRigidBodyCollisionGroups=[low(TKraftRigidBodyCollisionGroup)..high(TKraftRigidBodyCollisionGroup)];const TryIterations:longint=4):boolean;
var Hit:longbool;
    AABB:TKraftAABB;
    Sphere:TKraftSphere;
    SumMinimumTranslationVector:TKraftVector3;
    Count:longint;
 procedure CollideSphereWithSphere(Shape:TKraftShapeSphere); {$ifdef caninline}inline;{$endif}
 var Position,Normal:TKraftVector3;
     Depth:TKraftScalar;
 begin
  Position:=Vector3Sub(Sphere.Center,Vector3TermMatrixMul(Shape.LocalCenterOfMass,Shape.WorldTransform));
  if Vector3Length(Position)<(Sphere.Radius+Shape.Radius) then begin
   Normal:=Vector3SafeNorm(Position);
   Depth:=(Sphere.Radius+Shape.Radius)-Vector3Length(Position);
   SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Normal,Depth));
   inc(Count);
   Hit:=true;
  end;
 end;
 procedure CollideSphereWithCapsule(Shape:TKraftShapeCapsule); {$ifdef caninline}inline;{$endif}
 var Alpha,HalfLength,r1,r2,d,d1:TKraftScalar;
     Center,Position,Normal,GeometryDirection:TKraftVector3;
 begin
  r1:=Shape.Radius;
  r2:=Sphere.Radius;
  GeometryDirection:=Vector3(Shape.WorldTransform[1,0],Shape.WorldTransform[1,1],Shape.WorldTransform[1,2]);
  Center:=Vector3TermMatrixMul(Shape.LocalCenterOfMass,Shape.WorldTransform);
  Alpha:=(GeometryDirection.x*(Sphere.Center.x-Center.x))+
         (GeometryDirection.y*(Sphere.Center.y-Center.y))+
         (GeometryDirection.z*(Sphere.Center.z-Center.z));
  HalfLength:=Shape.Height*0.5;
  if Alpha>HalfLength then begin
   Alpha:=HalfLength;
  end else if alpha<-HalfLength then begin
   Alpha:=-HalfLength;
  end;
  Position:=Vector3Add(Center,Vector3ScalarMul(GeometryDirection,Alpha));
  d:=Vector3Dist(Position,Sphere.Center);
  if d<=(r1+r2) then begin
   if d<=EPSILON then begin
    SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Vector3XAxis,r1+r2));
    inc(Count);
    Hit:=true;
   end else begin
    d1:=1.0/d;
    Normal:=Vector3Neg(Vector3ScalarMul(Vector3Sub(Position,Sphere.Center),d1));
    SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Normal,(r1+r2)-d));
    inc(Count);
    Hit:=true;
   end;
  end;
 end;
 procedure CollideSphereWithConvexHull(Shape:TKraftShapeConvexHull); {$ifdef caninline}inline;{$endif}
 var FaceIndex,ClosestFaceIndex,VertexIndex:longint;
     Distance,ClosestDistance,BestClosestPointDistance,d:TKraftScalar;
     SphereCenter,Normal,ClosestPoint,BestClosestPoint,BestClosestPointNormal,ab,ap,a,b,v,n:TKraftVector3;
     InsideSphere,InsidePolygon,HasBestClosestPoint:boolean;
     Face:PKraftConvexHullFace;
 begin
  BestClosestPointDistance:=3.4e+38;
  HasBestClosestPoint:=false;
  ClosestDistance:=3.4e+38;
  ClosestFaceIndex:=-1;
  InsideSphere:=true;
  SphereCenter:=Vector3TermMatrixMulInverted(Sphere.Center,Shape.WorldTransform);
  for FaceIndex:=0 to Shape.ConvexHull.CountFaces-1 do begin
   Face:=@Shape.ConvexHull.Faces[FaceIndex];
   Distance:=PlaneVectorDistance(Face^.Plane,SphereCenter);
   if Distance>0.0 then begin
    // sphere center is not inside in the convex hull . . .
    if Distance<Sphere.Radius then begin
     // but touching . . .
     if Face^.CountVertices>0 then begin
      InsidePolygon:=true;
      n:=Face^.Plane.Normal;
      b:=Shape.ConvexHull.Vertices[Face^.Vertices[Face^.CountVertices-1]].Position;
      for VertexIndex:=0 to Face^.CountVertices-1 do begin
       a:=b;
       b:=Shape.ConvexHull.Vertices[Face^.Vertices[VertexIndex]].Position;
       ab:=Vector3Sub(b,a);
       ap:=Vector3Sub(SphereCenter,a);
       v:=Vector3Cross(ab,n);
       if Vector3Dot(ap,v)>0.0 then begin
        d:=Vector3LengthSquared(ab);
        if d<>0.0 then begin
         d:=Vector3Dot(ab,ap)/d;
        end else begin
         d:=0.0;
        end;
        ClosestPoint:=Vector3Lerp(a,b,d);
        InsidePolygon:=false;
        break;
       end;
      end;
      if InsidePolygon then begin
       // sphere is directly touching the convex hull . . .
       Normal:=Vector3SafeNorm(Vector3TermMatrixMulBasis(Shape.ConvexHull.Faces[FaceIndex].Plane.Normal,Shape.WorldTransform));
       SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Normal,Sphere.Radius-Distance));
       inc(Count);
       Hit:=true;
       exit;
      end else begin
       // the sphere may not be directly touching the polyhedron, but it may be touching a point or an edge, if the distance between
       // the closest point on the poly and the center of the sphere is less than the sphere radius we have a hit.
       Normal:=Vector3Sub(SphereCenter,ClosestPoint);
       if Vector3LengthSquared(Normal)<sqr(Sphere.Radius) then begin
        Normal:=Vector3TermMatrixMulBasis(Normal,Shape.WorldTransform);
        Distance:=Vector3LengthNormalize(Normal);
        if (not HasBestClosestPoint) or (BestClosestPointDistance>Distance) then begin
         HasBestClosestPoint:=true;
         BestClosestPointDistance:=Distance;
         BestClosestPoint:=ClosestPoint;
         BestClosestPointNormal:=Normal;
        end;
       end;
      end;
     end;
    end;
    InsideSphere:=false;
   end else if InsideSphere and ((ClosestFaceIndex<0) or (ClosestDistance>abs(Distance))) then begin
    ClosestDistance:=abs(Distance);
    ClosestFaceIndex:=FaceIndex;
   end;
  end;
  if InsideSphere and (ClosestFaceIndex>=0) then begin
   // the sphere center is inside the convex hull . . .
   Normal:=Vector3SafeNorm(Vector3TermMatrixMulBasis(Shape.ConvexHull.Faces[ClosestFaceIndex].Plane.Normal,Shape.WorldTransform));
   SumMinimumTranslationVector:=Vector3Sub(SumMinimumTranslationVector,Vector3ScalarMul(Normal,ClosestDistance-Sphere.Radius));
   inc(Count);
   Hit:=true;
  end else if HasBestClosestPoint then begin
   SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(BestClosestPointNormal),Sphere.Radius-BestClosestPointDistance));
   inc(Count);
   Hit:=true;
  end;
 end;
 procedure CollideSphereWithBox(Shape:TKraftShapeBox); {$ifdef caninline}inline;{$endif}
 const ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
 var IntersectionDist,ContactDist,DistSqr,Distance,FaceDist,MinDist:TKraftScalar;
     SphereRelativePosition,ClosestPoint,Normal:TKraftVector3;
     Axis,AxisSign:longint;
 begin
  SphereRelativePosition:=Vector3TermMatrixMulInverted(Sphere.Center,Shape.WorldTransform);
  ClosestPoint.x:=Min(Max(SphereRelativePosition.x,-Shape.Extents.x),Shape.Extents.x);
  ClosestPoint.y:=Min(Max(SphereRelativePosition.y,-Shape.Extents.y),Shape.Extents.y);
  ClosestPoint.z:=Min(Max(SphereRelativePosition.z,-Shape.Extents.z),Shape.Extents.z);
  Normal:=Vector3Sub(SphereRelativePosition,ClosestPoint);
  DistSqr:=Vector3LengthSquared(Normal);
  IntersectionDist:=Sphere.Radius;
  ContactDist:=IntersectionDist+EPSILON;
  if DistSqr<=sqr(ContactDist) then begin
   if DistSqr<=EPSILON then begin
    begin
     FaceDist:=Shape.Extents.x-SphereRelativePosition.x;
     MinDist:=FaceDist;
     Axis:=0;
     AxisSign:=1;
    end;
    begin
     FaceDist:=Shape.Extents.x+SphereRelativePosition.x;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=0;
      AxisSign:=-1;
     end;
    end;
    begin
     FaceDist:=Shape.Extents.y-SphereRelativePosition.y;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=1;
      AxisSign:=1;
     end;
    end;
    begin
     FaceDist:=Shape.Extents.y+SphereRelativePosition.y;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=1;
      AxisSign:=-1;
     end;
    end;
    begin
     FaceDist:=Shape.Extents.z-SphereRelativePosition.z;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=2;
      AxisSign:=1;
     end;
    end;
    begin
     FaceDist:=Shape.Extents.z+SphereRelativePosition.z;
     if FaceDist<MinDist then begin
      MinDist:=FaceDist;
      Axis:=2;
      AxisSign:=-1;
     end;
    end;
    ClosestPoint:=SphereRelativePosition;
    ClosestPoint.xyz[Axis]:=Shape.Extents.xyz[Axis]*AxisSign;
    Normal:=Vector3Origin;
    Normal.xyz[Axis]:=AxisSign;
    Distance:=-MinDist;
   end else begin
    Distance:=Vector3LengthNormalize(Normal);
   end;
   SumMinimumTranslationVector:=Vector3Sub(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(Vector3TermMatrixMulBasis(Normal,Shape.WorldTransform)),Distance-IntersectionDist));
   inc(Count);
   Hit:=true;
  end;
 end;
 procedure CollideSphereWithPlane(Shape:TKraftShapePlane); {$ifdef caninline}inline;{$endif}
 var Distance:TKraftScalar;
     SphereCenter:TKraftVector3;
 begin
  SphereCenter:=Vector3TermMatrixMulInverted(Sphere.Center,Shape.WorldTransform);
  Distance:=PlaneVectorDistance(Shape.Plane,SphereCenter);
  if Distance<=Sphere.Radius then begin
   SumMinimumTranslationVector:=Vector3Sub(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(Vector3TermMatrixMulBasis(Shape.Plane.Normal,Shape.WorldTransform)),Distance-Sphere.Radius));
   inc(Count);
   Hit:=true;
  end;
 end;
 procedure CollideSphereWithTriangle(Shape:TKraftShapeTriangle);
 const ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
 var i:longint;
     Radius,RadiusWithThreshold,DistanceFromPlane,ContactRadiusSqr,DistanceSqr:TKraftScalar;
     SphereCenter,Normal,P0ToCenter,ContactPoint,NearestOnEdge,ContactToCenter:TKraftVector3;
     IsInsideContactPlane,HasContact:boolean;
     v:array[0..2] of PKraftVector3;
 begin
  v[0]:=@Shape.ConvexHull.Vertices[0].Position;
  v[1]:=@Shape.ConvexHull.Vertices[1].Position;
  v[2]:=@Shape.ConvexHull.Vertices[2].Position;
  SphereCenter:=Vector3TermMatrixMulInverted(Sphere.Center,Shape.WorldTransform);
  Radius:=Sphere.Radius;
  RadiusWithThreshold:=Radius+EPSILON;
  Normal:=Shape.ConvexHull.Faces[0].Plane.Normal;// Vector3SafeNorm(Vector3Cross(Vector3Sub(v[1]^,v[0]^),Vector3Sub(v[2]^,v[0]^)));
  P0ToCenter:=Vector3Sub(SphereCenter,v[0]^);
  DistanceFromPlane:=Vector3Dot(P0ToCenter,Normal);
  if DistanceFromPlane<0.0 then begin
   DistanceFromPlane:=-DistanceFromPlane;
   Normal:=Vector3Neg(Normal);
  end;
  IsInsideContactPlane:=DistanceFromPlane<RadiusWithThreshold;
  HasContact:=false;
  ContactPoint:=Vector3Origin;
  ContactRadiusSqr:=sqr(RadiusWithThreshold);
  if IsInsideContactPlane then begin
   if PointInTriangle(v[0]^,v[1]^,v[2]^,Normal,SphereCenter) then begin
    HasContact:=true;
    ContactPoint:=Vector3Sub(SphereCenter,Vector3ScalarMul(Normal,DistanceFromPlane));
   end else begin
    for i:=0 to 2 do begin
     DistanceSqr:=SegmentSqrDistance(v[i]^,v[ModuloThree[i+1]]^,SphereCenter,NearestOnEdge);
     if DistanceSqr<ContactRadiusSqr then begin
      HasContact:=true;
      ContactPoint:=NearestOnEdge;
     end;
    end;
   end;
  end;
  if HasContact then begin
   ContactToCenter:=Vector3Sub(SphereCenter,ContactPoint);
   DistanceSqr:=Vector3LengthSquared(ContactToCenter);
   if DistanceSqr<ContactRadiusSqr then begin
    if DistanceSqr>EPSILON then begin
     SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(Vector3TermMatrixMulBasis(ContactToCenter,Shape.WorldTransform)),Radius-sqrt(DistanceSqr)));
     inc(Count);
     Hit:=true;
    end else begin
     SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(Vector3TermMatrixMulBasis(Normal,Shape.WorldTransform)),Radius));
     inc(Count);
     Hit:=true;
    end;
   end;
  end;
 end;
 procedure CollideSphereWithMesh(Shape:TKraftShapeMesh); {$ifdef caninline}inline;{$endif}
 const ModuloThree:array[0..5] of longint=(0,1,2,0,1,2);
 var i,SkipListNodeIndex,TriangleIndex:longint;
     Radius,RadiusWithThreshold,DistanceFromPlane,ContactRadiusSqr,DistanceSqr:TKraftScalar;
     SphereCenter,Normal,P0ToCenter,ContactPoint,NearestOnEdge,ContactToCenter:TKraftVector3;
     IsInsideContactPlane,HasContact:boolean;
     SkipListNode:PKraftMeshSkipListNode;
     Triangle:PKraftMeshTriangle;
     AABB:TKraftAABB;
     Vertices:array[0..2] of PKraftVector3;
 begin
  SphereCenter:=Vector3TermMatrixMulInverted(Sphere.Center,Shape.WorldTransform);
  Radius:=Sphere.Radius;
  RadiusWithThreshold:=Radius+0.1;
  AABB.Min.x:=SphereCenter.x-RadiusWithThreshold;
  AABB.Min.y:=SphereCenter.y-RadiusWithThreshold;
  AABB.Min.z:=SphereCenter.z-RadiusWithThreshold;
  AABB.Max.x:=SphereCenter.x+RadiusWithThreshold;
  AABB.Max.y:=SphereCenter.y+RadiusWithThreshold;
  AABB.Max.z:=SphereCenter.z+RadiusWithThreshold;
  RadiusWithThreshold:=Radius+EPSILON;
  SkipListNodeIndex:=0;
  while SkipListNodeIndex<Shape.Mesh.CountSkipListNodes do begin
   SkipListNode:=@Shape.Mesh.SkipListNodes[SkipListNodeIndex];
   if AABBIntersect(SkipListNode^.AABB,AABB) then begin
    TriangleIndex:=SkipListNode^.TriangleIndex;
    while TriangleIndex>=0 do begin
     Triangle:=@Shape.Mesh.Triangles[TriangleIndex];
     Vertices[0]:=@Shape.Mesh.Vertices[Triangle^.Vertices[0]];
     Vertices[1]:=@Shape.Mesh.Vertices[Triangle^.Vertices[1]];
     Vertices[2]:=@Shape.Mesh.Vertices[Triangle^.Vertices[2]];
     Normal:=Vector3SafeNorm(Vector3Cross(Vector3Sub(Vertices[1]^,Vertices[0]^),Vector3Sub(Vertices[2]^,Vertices[0]^)));
     P0ToCenter:=Vector3Sub(SphereCenter,Vertices[0]^);
     DistanceFromPlane:=Vector3Dot(P0ToCenter,Normal);
     if DistanceFromPlane<0.0 then begin
      DistanceFromPlane:=-DistanceFromPlane;
      Normal:=Vector3Neg(Normal);
     end;
     IsInsideContactPlane:=DistanceFromPlane<RadiusWithThreshold;
     HasContact:=false;
     ContactPoint:=Vector3Origin;
     ContactRadiusSqr:=sqr(RadiusWithThreshold);
     if IsInsideContactPlane then begin
      if PointInTriangle(Vertices[0]^,Vertices[1]^,Vertices[2]^,Normal,SphereCenter) then begin
       HasContact:=true;
       ContactPoint:=Vector3Sub(SphereCenter,Vector3ScalarMul(Normal,DistanceFromPlane));
      end else begin
       for i:=0 to 2 do begin
        DistanceSqr:=SegmentSqrDistance(Vertices[i]^,Vertices[ModuloThree[i+1]]^,SphereCenter,NearestOnEdge);
        if DistanceSqr<ContactRadiusSqr then begin
         HasContact:=true;
         ContactPoint:=NearestOnEdge;
        end;
       end;
      end;
     end;
     if HasContact then begin
      ContactToCenter:=Vector3Sub(SphereCenter,ContactPoint);
      DistanceSqr:=Vector3LengthSquared(ContactToCenter);
      if DistanceSqr<ContactRadiusSqr then begin
       if DistanceSqr>EPSILON then begin
        SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(Vector3TermMatrixMulBasis(ContactToCenter,Shape.WorldTransform)),Radius-sqrt(DistanceSqr)));
        inc(Count);
        Hit:=true;
       end else begin
        SumMinimumTranslationVector:=Vector3Add(SumMinimumTranslationVector,Vector3ScalarMul(Vector3SafeNorm(Vector3TermMatrixMulBasis(Normal,Shape.WorldTransform)),Radius));
        inc(Count);
        Hit:=true;
       end;
      end;
     end;
     TriangleIndex:=Triangle^.Next;
    end;
    inc(SkipListNodeIndex);
   end else begin
    SkipListNodeIndex:=SkipListNode^.SkipToNodeIndex;
   end;
  end;
 end;
 procedure QueryTree(AABBTree:TKraftDynamicAABBTree);
 var LocalStack:PKraftDynamicAABBTreeLongintArray;
     LocalStackPointer,NodeID:longint;
     Node:PKraftDynamicAABBTreeNode;
     CurrentShape:TKraftShape;
 begin
  if assigned(AABBTree) then begin
   if AABBTree.Root>=0 then begin
    LocalStack:=AABBTree.Stack;
    LocalStack^[0]:=AABBTree.Root;
    LocalStackPointer:=1;
    while LocalStackPointer>0 do begin
     dec(LocalStackPointer);
     NodeID:=LocalStack^[LocalStackPointer];
     if NodeID>=0 then begin
      Node:=@AABBTree.Nodes[NodeID];
      if AABBIntersect(Node^.AABB,AABB) then begin
       if Node^.Children[0]<0 then begin
        CurrentShape:=Node^.UserData;
        if assigned(CurrentShape) and (assigned(CurrentShape.RigidBody) and ((CurrentShape.RigidBody.CollisionGroups*CollisionGroups)<>[])) then begin
         case CurrentShape.ShapeType of
          kstSphere:begin
           CollideSphereWithSphere(TKraftShapeSphere(CurrentShape));
          end;
          kstCapsule:begin
           CollideSphereWithCapsule(TKraftShapeCapsule(CurrentShape));
          end;
          kstConvexHull:begin
           CollideSphereWithConvexHull(TKraftShapeConvexHull(CurrentShape));
          end;
          kstBox:begin
           CollideSphereWithBox(TKraftShapeBox(CurrentShape));
          end;
          kstPlane:begin
           CollideSphereWithPlane(TKraftShapePlane(CurrentShape));
          end;
          kstTriangle:begin
           CollideSphereWithTriangle(TKraftShapeTriangle(CurrentShape));
          end;
          kstMesh:begin
           CollideSphereWithMesh(TKraftShapeMesh(CurrentShape));
          end;
         end;
        end;
       end else begin
        if AABBTree.StackCapacity<=(LocalStackPointer+2) then begin
         AABBTree.StackCapacity:=RoundUpToPowerOfTwo(LocalStackPointer+2);
         ReallocMem(AABBTree.Stack,AABBTree.StackCapacity*SizeOf(longint));
         LocalStack:=AABBTree.Stack;
        end;
        LocalStack^[LocalStackPointer+0]:=Node^.Children[0];
        LocalStack^[LocalStackPointer+1]:=Node^.Children[1];
        inc(LocalStackPointer,2);
       end;
      end;
     end;
    end;
   end;
  end;
 end;
var TryCounter:longint;
begin
 result:=false;
 for TryCounter:=1 to TryIterations do begin
  Hit:=false;
  AABB.Min.x:=Center.x-Radius;
  AABB.Min.y:=Center.y-Radius;
  AABB.Min.z:=Center.z-Radius;
  AABB.Max.x:=Center.x+Radius;
  AABB.Max.y:=Center.y+Radius;
  AABB.Max.z:=Center.z+Radius;
  Sphere.Center:=Center;
  Sphere.Radius:=Radius;
  SumMinimumTranslationVector:=Vector3Origin;
  Count:=0;
  QueryTree(StaticAABBTree);
  QueryTree(SleepingAABBTree);
  QueryTree(DynamicAABBTree);
  QueryTree(KinematicAABBTree);
  result:=result or Hit;
  if (Count>0) and not IsZero(Vector3LengthSquared(SumMinimumTranslationVector)) then begin
   Center.x:=Center.x+(SumMinimumTranslationVector.x/Count);
   Center.y:=Center.y+(SumMinimumTranslationVector.y/Count);
   Center.z:=Center.z+(SumMinimumTranslationVector.z/Count);
  end else begin
   break;
  end;
 end;
end;

function TKraft.GetDistance(const ShapeA,ShapeB:TKraftShape):TKraftScalar;
var GJK:TKraftGJK;
begin
 GJK.CachedSimplex:=nil;
 GJK.Simplex.Count:=0;
 GJK.Shapes[0]:=ShapeA;
 GJK.Shapes[1]:=ShapeB;
 GJK.Transforms[0]:=@ShapeA.WorldTransform;
 GJK.Transforms[1]:=@ShapeB.WorldTransform;
 GJK.UseRadii:=false;
 GJK.Run;
 result:=GJK.Distance;
end;

initialization
 CheckCPU;
end.