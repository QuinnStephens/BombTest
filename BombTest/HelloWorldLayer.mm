//
//  HelloWorldLayer.mm
//  BombTest
//
//  Created by Quinn Stephens on 3/31/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

// enums that will be used as tags
enum {
	kTagTileMap = 1,
	kTagBatchNode = 1,
	kTagAnimation1 = 1,
    kTagBomb = 2,
};


// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// enable touches
		self.isTouchEnabled = YES;
		
		// enable accelerometer
		self.isAccelerometerEnabled = YES;
		
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
		
		// Define the gravity vector.
		b2Vec2 gravity;
		gravity.Set(0.0f, -10.0f);
		
		// Do we want to let bodies sleep?
		// This will speed up the physics simulation
		bool doSleep = true;
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		world = new b2World(gravity, doSleep);
		
		world->SetContinuousPhysics(true);
		
		// Debug Draw functions
		m_debugDraw = new GLESDebugDraw( PTM_RATIO );
		world->SetDebugDraw(m_debugDraw);
		
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
//		flags += b2DebugDraw::e_jointBit;
//		flags += b2DebugDraw::e_aabbBit;
//		flags += b2DebugDraw::e_pairBit;
//		flags += b2DebugDraw::e_centerOfMassBit;
		m_debugDraw->SetFlags(flags);		
		
		
		// Define the ground body.
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0, 0); // bottom-left corner
        NSString *groundString  = @"ground";
        groundBodyDef.userData = groundString;
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		b2Body* groundBody = world->CreateBody(&groundBodyDef);
		
		// Define the ground box shape.
		b2PolygonShape groundBox;		
		
		// bottom
		groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(screenSize.width * 2 /PTM_RATIO,0));
		groundBody->CreateFixture(&groundBox,0);
		
		// top
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width * 2/PTM_RATIO,screenSize.height/PTM_RATIO));
		groundBody->CreateFixture(&groundBox,0);
		
		// left
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
		groundBody->CreateFixture(&groundBox,0);
		
		// right
		groundBox.SetAsEdge(b2Vec2(screenSize.width * 2/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width * 2/PTM_RATIO,0));
		groundBody->CreateFixture(&groundBox,0);
        
        contactListener = new MyContactListener();
        world->SetContactListener(contactListener);
        
        // Add objects layer
        objectsLayer = [[CCNode alloc] init];
        [self addChild:objectsLayer];
        
		
        [self createAssortedShapes];
		
		[self schedule: @selector(tick:)];
	}
	return self;
}

-(void) draw
{
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

}

-(void) createAssortedShapes{
    int numShapes = 50;
    for (int i = 0; i < numShapes; i++){
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        NSString *boxString  = @"box";
        bodyDef.userData = boxString;
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
        
        bodyDef.position.Set((CCRANDOM_0_1() * 640) / PTM_RATIO, (CCRANDOM_0_1() * 100) / PTM_RATIO);
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;	
        fixtureDef.density = 1.0f;
        fixtureDef.friction = 0.3f;
        fixtureDef.restitution = 0.5f;
        
        b2Body *body = world->CreateBody(&bodyDef);
        body->CreateFixture(&fixtureDef);
        
    }
}

-(void) dropBomb:(CGPoint)p
{
	
	b2BodyDef bodyDef;
    b2Body *body;
	bodyDef.type = b2_dynamicBody;
    NSString *bombString = @"bomb";
    bodyDef.userData = bombString;
    
    b2CircleShape circle;
    circle.m_radius = (CCRANDOM_0_1() * 5 + 10.0)/PTM_RATIO;
    
    b2FixtureDef fd;
    fd.shape = &circle;
    fd.density = 1.0f;
    fd.friction = 0.1f;
    fd.restitution = 0.5f;
    bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
    body = world->CreateBody(&bodyDef);
    body->CreateFixture(&fd);
    
    //[allBombs addObject:[NSValue valueWithPointer:bomb]];

}

// Pos comes from the ccTouchesEnded function. I've already converted it to Cocos2D coordinates.
-(void) launchBomb:(b2Vec2) b2TouchPosition
{
	BOOL doSuction = NO; // Very cool looking implosion effect instead of explosion.
    
    //In Box2D the bodies are a linked list, so keep getting the next one until it doesn't exist.
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
        //Box2D uses meters, there's 32 pixels in one meter. PTM_RATIO is defined somewhere in the class.
		//b2Vec2 b2TouchPosition = b2Vec2(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
		b2Vec2 b2BodyPosition = b2Vec2(b->GetPosition().x, b->GetPosition().y);
        
        //Don't forget any measurements always need to take PTM_RATIO into account
		float maxDistance = 9; // In your head don't forget this number is low because we're multiplying it by 32 pixels;
		int maxForce = 2000;
		CGFloat distance; // Why do i want to use CGFloat vs float - I'm not sure, but this mixing seems to work fine for this little test.
		CGFloat strength;
		float force;
		CGFloat angle;
        
		if(doSuction) // To go towards the press, all we really change is the atanf function, and swap which goes first to reverse the angle
		{
			// Get the distance, and cap it
			distance = b2Distance(b2BodyPosition, b2TouchPosition);
			if(distance > maxDistance) distance = maxDistance - 0.01;
			// Get the strength
			//strength = distance / maxDistance; // Uncomment and reverse these two. and ones further away will get more force instead of less
			strength = (maxDistance - distance) / maxDistance; // This makes it so that the closer something is - the stronger, instead of further
			force  = strength * maxForce;
            
			// Get the angle
			angle = atan2f(b2TouchPosition.y - b2BodyPosition.y, b2TouchPosition.x - b2BodyPosition.x);
			//NSLog(@" distance:%0.2f,force:%0.2f", distance, force);
			// Apply an impulse to the body, using the angle
			b->ApplyForce(b2Vec2(cosf(angle) * force, sinf(angle) * force), b->GetPosition());
		}
		else
		{
			distance = b2Distance(b2BodyPosition, b2TouchPosition);
			if(distance > maxDistance) distance = maxDistance - 0.01;
            
			// Normally if distance is max distance, it'll have the most strength, this makes it so the opposite is true - closer = stronger
			strength = (maxDistance - distance) / maxDistance; // This makes it so that the closer something is - the stronger, instead of further
			force = strength * maxForce;
			angle = atan2f(b2BodyPosition.y - b2TouchPosition.y, b2BodyPosition.x - b2TouchPosition.x);
			//NSLog(@" distance:%0.2f,force:%0.2f,angle:%0.2f", distance, force, angle);
			// Apply an impulse to the body, using the angle
			b->ApplyForce(b2Vec2(cosf(angle) * force, sinf(angle) * force), b->GetPosition());
		}
	}
}



-(void) tick: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);

	
	//Iterate over the bodies in the physics world
    /*
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) {
			
		}	
	}*/
    
    // Check for collisions
    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for(pos = contactListener->_contacts.begin(); 
        pos != contactListener->_contacts.end(); ++pos) {
            MyContact contact = *pos;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
            NSString *stringA = (NSString *) bodyA->GetUserData();
            NSString *stringB = (NSString *) bodyB->GetUserData();
           // NSLog(stringA, stringB);
            if (stringA == @"bomb") {
                b2Body *bombBody = bodyA;
                [self launchBomb:bombBody->GetPosition()];
                toDestroy.push_back(bombBody);
            } 
            
            if (stringB == @"bomb"){
                b2Body *bombBody = bodyB;
                [self launchBomb:bombBody->GetPosition()];
                toDestroy.push_back(bombBody);
            }
        }
    }
    
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *b = *pos2;     
        if (b->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();
            [self removeChild:sprite cleanup:YES];
        }
        world->DestroyBody(b);
        //thisBomb = NULL;
    }
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
//- (void) recognizedTap:(UITapGestureRecognizer*)recognizer atLocation:(CGPoint)point {

	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
		
		[self dropBomb: location];
        
        //[self launchBomb:location];
     }
     
    
}


- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
	static float prevX=0, prevY=0;
	
	//#define kFilterFactor 0.05f
#define kFilterFactor 1.0f	// don't use filter. the code is here just as an example
	
	float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
	float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
	
	prevX = accelX;
	prevY = accelY;
	
	// accelerometer values are in "Portrait" mode. Change them to Landscape left
	// multiply the gravity by 10
	b2Vec2 gravity( -accelY * 10, accelX * 10);
	
	world->SetGravity( gravity );
}

// Gesture stuff


- (CGPoint) glPointForGestureRecognizer:(UIGestureRecognizer*)recognizer point:(CGPoint)point {
	return [[CCDirector sharedDirector] convertToGL:ccp([[CCDirector sharedDirector] winSize].height - point.y, point.x)];
}

- (CGPoint) glPointForGestureRecognizer:(UIGestureRecognizer*)recognizer {
	return [self glPointForGestureRecognizer:recognizer point:[recognizer locationInView:nil]];
}

	


- (void) recognizedPan:(UIPanGestureRecognizer*)recognizer {
	CGPoint point = [[CCDirector sharedDirector] convertToGL:[recognizer translationInView:recognizer.view]];
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		panPoint = CGPointZero;
	}
	else if (recognizer.state == UIGestureRecognizerStateChanged) {
		[objectsLayer setPosition:ccpAdd(objectsLayer.position, ccpSub(point, panPoint))];
	}
	panPoint = point;
}

- (void) recognizedPinch:(UIPinchGestureRecognizer*)recognizer {
	CGPoint point = [[CCDirector sharedDirector] convertToGL:[recognizer locationInView:recognizer.view]];
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		originalZoom = objectsLayer.scale;
	}
	else if (recognizer.state == UIGestureRecognizerStateChanged) {
		// Update scale and note difference from last zoom (for positioning)
		zoom = clampf(originalZoom * recognizer.scale, 0.25, 3.0);
		float zoomDiff = zoom / objectsLayer.scale;
		objectsLayer.scale = zoom;
		
		// Update layer position so we zoom around the pinch center
		CGPoint pos = objectsLayer.position;
		CGPoint newPosition = ccp(pos.x - (point.x - pos.x)*(zoomDiff-1.0f), pos.y - (point.y - pos.y)*(zoomDiff-1.0f));
		objectsLayer.position = newPosition;
	}
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	delete world;
	world = NULL;
	
	delete m_debugDraw;

	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
