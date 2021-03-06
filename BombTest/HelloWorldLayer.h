//
//  HelloWorldLayer.h
//  BombTest
//
//  Created by Quinn Stephens on 3/31/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "MyContactListener.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    MyContactListener *contactListener;
    //b2Fixture *thisBomb;
    NSMutableArray *allBombs;
    
    CCLayer *objectsLayer;
    
    // Input
	CGPoint panPoint;
	float zoom;
	float originalZoom;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

-(void) dropBomb:(CGPoint)p;

-(void) createAssortedShapes;

@end
