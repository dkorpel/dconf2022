/**
Header file for Super Mario 64

Defines types, names and addresses for the game's memory
*/
module n64.sm64h;

//0x2A = x, 0x2B = coin, 0x2C = mario, 0x2D = star
enum STR_COIN = "\x2B";
enum STR_MARIO = "\x2C";
enum STR_STAR = "\x2D";
enum STR_X = "\x2A";

/// Address of a symbol for the US version
struct US {
	uint address;
}

/// ditto
struct JP {
	uint address;
}

/// ditto
struct EU {
	uint address;
}

/// ditto
struct SH {
	uint address;
}

extern(C): @nogc: nothrow:

__gshared extern {
	@(JP(0), US(0x32D5D4))
	int globalTimer;

	@(JP(0), US(0x32D5E4))
	Controller* controller;

	@(JP(0), US(0x33B170))
	MarioState mario;

	@(JP(0), US(0x32D93C))
	MarioState* marioPtr;

	@(JP(0), US(0x361158))
	Object* marioObj;

	@(JP(0), US(0x33D488))
	Object[240] objArr;

	@(JP(0x35FDF0), US(0x361160))
	Object* currObj;

	@(JP(0x38EEE0), US(0x38EEE0))
	short rngSeed;

	@(JP(0x32CE6C), US(0x32DDCC))
	void* structWithGfxRoot;

	@(US(0x33D480))
	uint timeStop; // bit flag 0x0002 = timestop

	@(US(0x361158))
	Camera camera;

	@(US(0x33B254))
	short transitionShrinking; /// goes to 0 when bowser face zooms out
	@(US(0x330EC0))
	ubyte transitionProgress; /// goes up from 0 when entering level
	@(US(0x33BAB0))
	short transitionType; /// 256 == level entry

	@(US(0x386000))
	float[0x4000] sinTable;
	@(US(0x387000))
	float[0x4000] cosTable;

	alias Mtx = short[32];

	short gMatStackIndex;
	Mat4[32] gMatStack;
	Mtx*[32] gMatStackFixed;

	byte gShowDebugText;
}

enum MarioAction : uint {
	startTeleport = 0x00001336,
	stopTeleport = 0x00001337,
	starDanceGround = 0x00001302,
	starDanceGroundNoExit = 0x00001307,
	starDanceWater = 0x00001303,
	fallingWithStar = 0x00001904,
	debugMove = 0x04000440,
	inCannon = 0x00001371,
	shootingOutOfCannon = 0x00880898,
	disappeared = 0x00001300,
	poleJump = 0x03000886,
	groundPoundLanding = 0x0080023C,
	swimming2 = 0x300024D1,
	inWater = 0x380022C0,
	spinningEnter = 0x00001924,
	exitWarpPipe = 0x00001923,
	stopSitting = 0x0C00023E,
	grandStarCutscene = 0x00001909,
}

enum MarioAnimationId {
	stopStarDanceGround = 206,
}

enum GfxId : uint {
	mario = 0x01,
	wingCap = 0x89,
}

enum uint behaviorLandscape = 0x13002A48; // U version
enum uint behaviorWingCapBlock = 0x13002250;

@(US(0x3273F0))
void* memcpy(void* destination, const void* source, size_t num);

@(US(0x2D62D8))
void drawStringFormat(int xPos, int yPos, const(char)* format_string, int content);

@(US(0x27D6FC))
void renderObject(Object* object);

@(US(0x385C00))
void processObject();

@(US(0x320544))
void playMusic(byte mode = 0, byte track = 10, int a2 = 0);

@(US(0x29EDCC))
Object* spawnObjectAtParent(Object* parent, int gfxId, uint behavior);

@(US(0x2509B8))
void setAnimation(MarioState* mario, int animation);

@(US(0x2D77DC))
void printGenericText(short x, short y, const(char)* str);

@(US(0x2DAA34))
void printCreditsString(short x, short y, const(char)* str);

@(US(0x27B904), JP(0x2DAA34))
void geoAppendDisplayList(void* list, int index);

@(US(0), JP(0))
void* allocDisplayList(uint size);

@(US(0x8037A434), JP(0))
void mtxf_to_mtx(short* mtx, float* mtxf);

@(US(0), JP(0))
void mtxf_mul(Mat4* dest, Mat4* a, Mat4* b);

ushort randomU16();

// type = 0x0114
struct GraphNodeCam
{
	GraphNode node;
	/* 0x14 */ void* updateFunc;
	/* 0x18 */ uint unk;
	/* 0x1C */ Vec3f from;
	/* 0x28 */ Vec3f to;
}

struct GraphNodeProj3D
{
	GraphNode node;
	/* 0x14 */ void* updateFunc;
	/* 0x18 */ uint unk;
	/* 0x1C */ float fov;
	/* 0x20 */ short zmin;
	/* 0x22 */ short zmax;
}

struct Camera
{
	ubyte[0x80] unkwown;
	Vec3f to; // 0x80
	Vec3f from; //0x8C
	Vec3f toTarget; // 0x98 - not verified
	Vec3f fromTarget; //0xA4
}

////////////////////////////////////////////////////////////////

struct OSContStatus {}
struct OSContPad {}
struct ChainSegment{}

alias s8 = byte;
alias u8 = ubyte;
alias s16 = short;
alias u16 = ushort;
alias s32 = int;
alias u32 = uint;
alias f32 = float;

struct Controller
{
	/*0x00*/ s16 rawStickX;       //
	/*0x02*/ s16 rawStickY;       //
	/*0x04*/ float stickX;        // [-64, 64] positive is right
	/*0x08*/ float stickY;        // [-64, 64] positive is up
	/*0x0C*/ float stickMag;      // distance from center [0, 64]
	/*0x10*/ u16 buttonDown;
	/*0x12*/ u16 buttonPressed;
	/*0x14*/ OSContStatus* statusData;
	/*0x18*/ OSContPad* controllerData;
};

enum Button : ushort
{
	A=0x8000,
	B=0x4000,
	Z=0x2000,
	start=0x1000,
	dpad_up=0x0800,
	dpad_down=0x0400,
	dpad_left=0x0200,
	dpad_right=0x0100,
	demo=0x0080,
	unused=0x0040,
	L=0x0020,
	R=0x0010,
	c_up=0x0008,
	c_down=0x0004,
	c_left=0x0002,
	c_right=0x0001,
}

struct Vec3f {
	float x;
	float y;
	float z;
}

struct Vec3s {
	short x;
	short y;
	short z;
}

alias Mat4 = float[4][4];

struct Animation {
	/*0x00*/ s16 flags;
	/*0x02*/ s16 unk02;
	/*0x04*/ s16 unk04;
	/*0x06*/ s16 unk06;
	/*0x08*/ s16 unk08;
	/*0x0A*/ s16 unk0A;
	/*0x0C*/ void *values;
	/*0x10*/ void *index;
	/*0x14*/ u32 length; // only used with Mario animations to determine how much to load. 0 otherwise.
}

struct GraphNode
{
	/*0x00*/ s16 type; // structure type
	/*0x02*/ s16 flags; // hi = drawing layer, lo = rendering modes
	/*0x04*/ GraphNode* prev;
	/*0x08*/ GraphNode* next;
	/*0x0C*/ GraphNode* parent;
	/*0x10*/ GraphNode* children;
}

struct GraphNodeObject_sub
{
	/*0x00 0x38*/ s16 animID;
	/*0x02 0x3A*/ s16 animYTrans;
	/*0x04 0x3C*/ Animation *curAnim;
	/*0x08 0x40*/ s16 animFrame;
	/*0x0A 0x42*/ u16 animTimer;
	/*0x0C 0x44*/ s32 animFrameAccelAssist;
	/*0x10 0x48*/ s32 animAccel;
};

struct GraphNodeObject
{
	/*0x00*/ GraphNode node;
	/*0x14*/ GraphNode *asGraphNode;
	/*0x18*/ s8 unk18;
	/*0x19*/ s8 unk19;
	/*0x1A*/ Vec3s angle;
	/*0x20*/ Vec3f pos;
	/*0x2C*/ Vec3f scale;
	/*0x38*/ GraphNodeObject_sub sub;
	/*0x4C*/ SpawnInfo *unk4C;
	/*0x50*/ void* throwMatrix; // matrix ptr
	/*0x54*/ f32 unk54;
	/*0x58*/ f32 unk58;
	/*0x5C*/ f32 unk5C;
}

struct Surface
{
	/*0x00*/ s16 type;
	/*0x02*/ s16 force;
	/*0x04*/ s8 flags;
	/*0x05*/ s8 room;
	/*0x06*/ s16 lowerY;
	/*0x08*/ s16 upperY;
	/*0x0A*/ Vec3s vertex1;
	/*0x10*/ Vec3s vertex2;
	/*0x16*/ Vec3s vertex3;
	/*0x1C*/ Vec3f normal;
	/*0x28*/ f32 originOffset;
	/*0x2C*/ Object* object;
}

struct ObjectNode
{
	GraphNodeObject gfx;
	ObjectNode *next;
	ObjectNode *prev;
}

struct Object
{
	/*0x000*/ ObjectNode header;
	/*0x068*/ Object *parentObj;
	/*0x06C*/ Object *prevObj;
	/*0x070*/ u32 collidedObjInteractTypes;
	/*0x074*/ s16 activeFlags;
	/*0x076*/ s16 numCollidedObjs;
	/*0x078*/ Object*[4] collidedObjs;
	/*0x088*/
	union U
	{
		//(\s[\w*]+)(\[0x50\]) -> $2$1
		// Object fields. See object_fields.h.
		u32[0x50] asU32;
		s32[0x50] asS32;
		s16[2][0x50] asS16;
		u8[4][0x50] asU8;
		f32[0x50] asF32;
		void[0x50] *asVoidP;
		s16[0x50] *asS16P;
		s32[0x50] *asS32P;
		u32[0x50] *asAnims;
		Waypoint[0x50] *asWaypoint;
		ChainSegment[0x50] *asChainSegment;
		Object[0x50] *asObject;
		Surface[0x50] *asSurface;
		void[0x50] *asVoidPtr;
	}
	U rawData;
	/*0x1C8*/ u32 unk1C8;
	/*0x1CC*/ u32 *behScript;
	/*0x1D0*/ u32 stackIndex;
	/*0x1D4*/ u32[8] stack;
	/*0x1F4*/ s16 unk1F4;
	/*0x1F6*/ s16 unk1F6;
	/*0x1F8*/ f32 hitboxRadius;
	/*0x1FC*/ f32 hitboxHeight;
	/*0x200*/ f32 hurtboxRadius;
	/*0x204*/ f32 hurtboxHeight;
	/*0x208*/ f32 hitboxDownOffset;
	/*0x20C*/ void *behavior;
	/*0x210*/ u32 unk210;
	/*0x214*/ Object *platform;
	/*0x218*/ void *collisionData;
	/*0x21C*/ Mat4 transform;
	/*0x25C*/ void *unk25C;
}
static assert(Object.sizeof == 0x260);

struct Waypoint
{
	s16 flags;
	Vec3s pos;
}

struct MarioAnimDmaRelatedThing
{
	u32 unk0;
	u32 unk4;
}

struct UnknownStruct6 {
	/*0x00*/ u32 unk00;
	/*0x04*/ Vec3f unk04;
	/*0x10*/ Vec3s unk10;
	/*0x16*/ s16 unk16;
	/*0x18*/ s16 unk18;
	u8[4] filler1A;
	/*0x1E*/ u16 unk1E;
	/*0x20*/ Object *unk20;
}

struct UnknownStruct4
{
	/*0x00*/ u32 unk00;
	/*0x04*/ u8 unk04;
	/*0x05*/ u8 unk05;
	/*0x06*/ u8 unk06;
	/*0x07*/ u8 unk07;
	/*0x08*/ s16 unk08;
	/*0x0A*/ s8 unk0A;
	/*0x0B*/ u8 unk0B;
	/*0x0C*/ s16 unk0C;
	/*0x0E*/ u8[2] filler0E;
	/*0x10*/ s16 unk10;
	/*0x12*/ s16 unk12;
	/*0x14*/ u16 unk14;
	/*0x16*/ u16 unk16;
	/*0x18*/ Vec3f unk18;
}

struct MarioAnimation
{
	MarioAnimDmaRelatedThing *animDmaTable;
	u32 currentDma;
	Animation *targetAnim;
	u8[4] padding;
}

struct WarpNode
{
	/*00*/ u8 id;
	/*01*/ u8 destLevel;
	/*02*/ u8 destArea;
	/*03*/ u8 destNode;
}

struct ObjectWarpNode
{
	/*0x00*/ WarpNode node;
	/*0x04*/ Object *object;
	/*0x08*/ ObjectWarpNode *next;
}

struct InstantWarp
{
	/*0x00*/ u8 unk00;
	/*0x01*/ u8 area;
	/*0x02*/ Vec3s displacement;
}

struct SpawnInfo
{
	/*0x00*/ Vec3s startPos;
	/*0x06*/ Vec3s startAngle;
	/*0x0C*/ s8 areaIndex;
	/*0x0D*/ s8 unk0D;
	/*0x10*/ u32 behaviorArg;
	/*0x14*/ void *behaviorScript;
	/*0x18*/ GraphNode *unk18;
	/*0x1C*/ SpawnInfo *next;
}

struct Whirlpool
{
	/*0x00*/ Vec3s pos;
	/*0x03*/ s16 strength;
}

struct Struct80280550 {}
struct UnknownArea28 {}

struct Area
{
	/*0x00*/ s8 index;
	/*0x01*/ s8 unk01;
	/*0x02*/ u16 unk02;
	/*0x04*/ GraphNode* unk04;
	/*0x08*/ s16* terrainData;
	/*0x0C*/ s8* surfaceRooms;
	/*0x10*/ s16* unk10;
	/*0x14*/ ObjectWarpNode* warpNodes;
	/*0x18*/ WarpNode* paintingWarpNodes;
	/*0x1C*/ InstantWarp* instantWarps;
	/*0x20*/ SpawnInfo* objectSpawnInfos;
	/*0x24*/ Struct80280550* unk24;
	/*0x28*/ UnknownArea28* unk28;
	/*0x2C*/ Whirlpool*[2] whirlpools;
	/*0x34*/ u8[1] unk34;
	/*0x35*/ u8 unk35;
	/*0x36*/ u16 unk36;
	/*0x38*/ u16 unk38;
}

struct MarioState
{
	/*0x00*/ u16 transformId; //J 263C14 / U 264024 setMarioObjectTransformFromTriangleSamples
	/*0x02*/ u16 input;
	/*0x04*/ u32 flags;
	/*0x08*/ u32 particleFlags;
	/*0x0C*/ u32 action;
	/*0x10*/ u32 prevAction;
	/*0x14*/ u32 unk14;
	/*0x18*/ u16 actionState;
	/*0x1A*/ u16 actionTimer;
	/*0x1C*/ u32 actionArg;
	/*0x20*/ f32 intendedMag;
	/*0x24*/ s16 intendedYaw;
	/*0x26*/ s16 invincTimer;
	/*0x28*/ u8 framesSinceA;
	/*0x29*/ u8 framesSinceB;
	/*0x2A*/ u8 wallKickTimer;
	/*0x2B*/ u8 doubleJumpTimer;
	/*0x2C*/ Vec3s faceAngle;
	/*0x32*/ Vec3s angleVel;
	/*0x38*/ s16 slideYaw;
	/*0x3A*/ s16 twirlYaw;
	/*0x3C*/ Vec3f pos;
	/*0x48*/ Vec3f vel;
	/*0x54*/ f32 forwardVel;
	/*0x58*/ f32 slideVelX;
	/*0x5C*/ f32 slideVelZ;
	/*0x60*/ Surface *wall;
	/*0x64*/ Surface *ceil;
	/*0x68*/ Surface *floor;
	/*0x6C*/ f32 ceilHeight;
	/*0x70*/ f32 floorHeight;
	/*0x74*/ s16 floorAngle;
	/*0x76*/ s16 waterLevel;
	/*0x78*/ Object *interactObj;
	/*0x7C*/ Object *heldObj;
	/*0x80*/ Object *usedObj;
	/*0x84*/ Object *riddenObj;
	/*0x88*/ Object *marioObj;
	/*0x8C*/ SpawnInfo *spawnInfo;
	/*0x90*/ Area *area;
	/*0x94*/ UnknownStruct6 *unk94;
	/*0x98*/ UnknownStruct4 *unk98;
	/*0x9C*/ Controller *controller;
	/*0xA0*/ MarioAnimation *animation;
	/*0xA4*/ u32 collidedObjInteractTypes;
	/*0xA8*/ s16 numCoins;
	/*0xAA*/ s16 numStars;
	/*0xAC*/ s8 numKeys; // Unused key mechanic
	/*0xAD*/ s8 numLives;
	/*0xAE*/ s16 health;
	/*0xB0*/ s16 unkB0;
	/*0xB2*/ u8 hurtCounter;
	/*0xB3*/ u8 healCounter;
	/*0xB4*/ u8 squishTimer;
	/*0xB5*/ u8 unkB5;
	/*0xB6*/ u16 capTimer;
	/*0xB8*/ s16 unkB8;
	/*0xBC*/ f32 peakHeight;
	/*0xC0*/ f32 quicksandDepth;
	/*0xC4*/ f32 unkC4;
}
static assert(MarioState.sizeof == 0xC8);

enum MusicMode : byte {
	set = 0,
	add = 1,
	reset = 2,
}

enum Track : byte {
	nothing = 0,
	starGet = 1,
	title = 2,
	battleField = 3,
	castle = 4,
	waterLevel = 5,
	sandLava = 6,
	koopaFight = 7,
	snow = 8,
	slider = 9,
	haunted = 10,
	lullaby = 11,
	underground = 12,
	starSelect = 13,
	invincible = 14,
	metalMario = 15,
	bowserMessage = 16,
	koopaRoad = 17,
	outOfPaintingJingle = 18,
	merryGoRound = 19,
	raceFanfare = 20,
	starAppear = 21,
	bossFight = 22,
	keyGet = 23,
	endlessStairs = 24,
	finalBowser = 25,
	credits = 26,
	solutionJingle = 27,
	toadMessage = 28,
	peachMessage = 29,
	intro = 30,
	grandStar = 31,
	peachSaved = 32,
	fileSelect = 33,
	lakituMessage = 34,
}

// display list light entry for e.g. Marios cap
struct Light
{
@nogc nothrow:
	uint ambient;
	uint ambient1;
	uint diffuse;
	uint diffuse1;
	byte[3] lightPos;
	byte _padding0;
	byte[3] lightPos1;
	byte _padding1;

	this(uint diffuse, uint ambient) {
		this.diffuse = diffuse;
		this.ambient = ambient;
		this.lightPos[0] = 0x28;
		this.lightPos[1] = 0x28;
		this.lightPos[2] = 0x28;
	}

	uint get8segmented() {
		return cast(uint) (&ambient) & 0xFF_FFFF;
	}
	uint get16segmented() {
		return cast(uint) (&diffuse) & 0xFF_FFFF;
	}
}
