//
//  GameViewController.m
//  DynamicFlappyBird
//
//  Created by Vitaly Berg on 27/04/14.
//  Copyright (c) 2014 Vitaly Berg. All rights reserved.
//

#import "GameViewController.h"

typedef NS_ENUM(NSInteger, GameState) {
    GameStateStart,
    GameStateGame,
    GameStateGameOver,
};

@interface GameViewController () <UICollisionBehaviorDelegate>

@property (weak, nonatomic) IBOutlet UIView *referenceView;
@property (weak, nonatomic) IBOutlet UIView *pipesView;
@property (weak, nonatomic) IBOutlet UIView *birdView;

@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UIPushBehavior *pushBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *birdBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *pipesBehavior;
@property (strong, nonatomic) UICollisionBehavior *pipesCollisionBehavior;

@property (assign, nonatomic) BOOL gaming;

@property (strong, nonatomic) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UIView *pipesTerminatorView;

@property (weak, nonatomic) IBOutlet UIView *splashView;

@property (strong, nonatomic) UIDynamicAnimator *gameOverAnimator;

@property (assign, nonatomic) GameState state;

@property (weak, nonatomic) IBOutlet UIView *gameOverView;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tap;

@end

@implementation GameViewController

#pragma mark - Setups

- (void)setupAnimator {
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.referenceView];
}

- (void)setupCollision {
    self.collisionBehavior = [[UICollisionBehavior alloc] init];
    [self.collisionBehavior addItem:self.birdView];
    self.collisionBehavior.collisionDelegate = self;
    self.collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:self.collisionBehavior];
}

- (void)setupGravity {
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.birdView]];
    self.gravityBehavior.gravityDirection = CGVectorMake(0, 1);
}

- (void)setupPush {
    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.birdView] mode:UIPushBehaviorModeInstantaneous];
    self.pushBehavior.active = NO;
    self.pushBehavior.pushDirection = CGVectorMake(0, -0.35);
    [self.animator addBehavior:self.pushBehavior];
}

- (void)setupBirdProperties {
    self.birdBehavior = [[UIDynamicItemBehavior alloc] init];
    [self.birdBehavior addItem:self.birdView];
    [self.animator addBehavior:self.birdBehavior];
    
    //self.birdBehavior.resistance = 4;
}

- (void)setupPipesBehavior {
    self.pipesBehavior = [[UIDynamicItemBehavior alloc] init];
    self.pipesBehavior.resistance = 0;
    self.pipesBehavior.friction = 0;
    self.pipesBehavior.density = 20;
    self.pipesBehavior.elasticity = 0;
    self.pipesBehavior.allowsRotation = NO;
    [self.animator addBehavior:self.pipesBehavior];
}

- (void)setupPipesCollisionBehavior {
    self.pipesCollisionBehavior = [[UICollisionBehavior alloc] init];
    [self.pipesCollisionBehavior addItem:self.birdView];
    self.pipesCollisionBehavior.collisionDelegate = self;
    self.pipesCollisionBehavior.collisionMode = UICollisionBehaviorModeItems;
    [self.animator addBehavior:self.pipesCollisionBehavior];
}

#pragma mark - Content

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(onTime:) userInfo:nil repeats:YES];
}

- (void)onTime:(id)sender {
    NSLog(@"On Time");
    
    CGFloat h = 130;
    
    CGFloat y = arc4random() % (440 - 20 - (NSInteger)h - 20);
    CGFloat topHeight = y + 20;
    CGFloat bottomHeight = 440 - h - topHeight;
    
    UIView *topPipe = [[UIView alloc] init];
    topPipe.frame = CGRectMake(440, 440, 40, topHeight);
    topPipe.backgroundColor = [UIColor colorWithRed:120/255.0 green:200/255.0 blue:120/255.0 alpha:1];
    [self.pipesView addSubview:topPipe];
    
    UIView *bottomPipe = [[UIView alloc] init];
    bottomPipe.frame = CGRectMake(440, 440 + topHeight + h, 40, bottomHeight);
    bottomPipe.backgroundColor = [UIColor colorWithRed:120/255.0 green:200/255.0 blue:120/255.0 alpha:1];
    [self.pipesView addSubview:bottomPipe];
    
    [self.pipesBehavior addItem:topPipe];
    [self.pipesBehavior addItem:bottomPipe];
    
    [self.pipesBehavior addLinearVelocity:CGPointMake(-80, 0) forItem:topPipe];
    [self.pipesBehavior addLinearVelocity:CGPointMake(-80, 0) forItem:bottomPipe];
    
    [self.pipesCollisionBehavior addItem:topPipe];
    [self.pipesCollisionBehavior addItem:bottomPipe];
}

- (void)killPipe:(id <UIDynamicItem>)pipe {
    if ([pipe isKindOfClass:[UIView class]]) {
        [(UIView *)pipe removeFromSuperview];
    }
    
    [self.pipesCollisionBehavior removeItem:pipe];
    [self.pipesBehavior removeItem:pipe];
}

- (void)gameOver {
    NSLog(@"%s", __func__);
    
    if (self.state == GameStateGameOver) {
        return;
    }
    
    self.tap.enabled = NO;
    
    [UIView animateWithDuration:0.2 delay:0.4 options:0 animations:^{
        self.gameOverView.alpha = 1;
    } completion:^(BOOL finished) {
        self.tap.enabled = YES;
    }];
    
    self.state = GameStateGameOver;
    
    [self.animator removeBehavior:self.pipesCollisionBehavior];
    [self.animator removeBehavior:self.pipesBehavior];
    
    [self.timer invalidate];
    self.timer = nil;
    
    self.gameOverAnimator = [[UIDynamicAnimator alloc] init];
    
    CGPoint p = self.view.center;
    
    UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[self.view] mode:UIPushBehaviorModeInstantaneous];
    push.pushDirection = CGVectorMake(0, 10);
    [self.gameOverAnimator addBehavior:push];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[self.view] mode:UIPushBehaviorModeInstantaneous];
        push.pushDirection = CGVectorMake(20, -10);
        [self.gameOverAnimator addBehavior:push];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[self.view] mode:UIPushBehaviorModeInstantaneous];
        push.pushDirection = CGVectorMake(-20, -10);
        [self.gameOverAnimator addBehavior:push];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.view snapToPoint:p];
        snapBehavior.damping = 1;
        [self.gameOverAnimator addBehavior:snapBehavior];
    });
    
    [UIView animateKeyframesWithDuration:0.2 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.3 animations:^{
            self.splashView.alpha = 1;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.7 animations:^{
            self.splashView.alpha = 0;
        }];
        
    } completion:^(BOOL finished) {
    }];
    
    /*
    [UIView animateWithDuration:0.08 animations:^{
        self.splashView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.splashView.alpha = 0;
        }];
    }];
     */
}


#pragma mark - UICollisionBehaviorDelegate

- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2 atPoint:(CGPoint)p {
    if (behavior == self.pipesCollisionBehavior) {
        if (item1 == self.birdView || item2 == self.birdView) {
            [self gameOver];
        }
        else if (item1 == self.pipesTerminatorView) {
            [self killPipe:item2];
        }
        else if (item2 == self.pipesTerminatorView) {
            [self killPipe:item1];
        }
    }
}

- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier atPoint:(CGPoint)p {
    if (behavior == self.collisionBehavior) {
        [self gameOver];
    }
}

#pragma mark - Actions

- (IBAction)handleTap:(id)sender {
    NSLog(@"%s", __func__);
    
    if (self.state == GameStateGameOver) {
        for (id item in self.pipesView.subviews) {
            [self.pipesCollisionBehavior removeItem:item];
            [self.pipesBehavior removeItem:item];
        }
        
        [self.pipesView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        self.gameOverView.alpha = 0;
        self.state = GameStateGame;
        self.gaming = NO;
        [self.animator removeBehavior:self.gravityBehavior];
        [self.animator addBehavior:self.pipesBehavior];
        [self.animator addBehavior:self.pipesCollisionBehavior];
        
        [self.birdBehavior removeItem:self.birdView];
        [self.pipesCollisionBehavior removeItem:self.birdView];
        [self.collisionBehavior removeItem:self.birdView];
        [self.gravityBehavior removeItem:self.birdView];
        [self.pushBehavior removeItem:self.birdView];
        
        self.birdView.center = CGPointMake(118, 665);
        
        [self.birdBehavior addItem:self.birdView];
        [self.pipesCollisionBehavior addItem:self.birdView];
        [self.collisionBehavior addItem:self.birdView];
        [self.gravityBehavior addItem:self.birdView];
        [self.pushBehavior addItem:self.birdView];
        
        return;
    }
    
    if (!self.gaming) {
        self.gaming = YES;
        [self.animator addBehavior:self.gravityBehavior];
        [self startTimer];
    }
    
    CGPoint p = [self.birdBehavior linearVelocityForItem:self.birdView];
    [self.birdBehavior addLinearVelocity:CGPointMake(0, -p.y) forItem:self.birdView];
    
    self.pushBehavior.active = YES;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.state = GameStateStart;
    
    [self setupAnimator];
    [self setupCollision];
    [self setupGravity];
    [self setupPush];
    [self setupBirdProperties];
    [self setupPipesBehavior];
    [self setupPipesCollisionBehavior];
}

@end
