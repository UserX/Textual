// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define CLICK_INTERVAL	2

@implementation GrowlController

@synthesize owner;
@synthesize growl;
@synthesize lastClickedContext;
@synthesize lastClickedTime;
@synthesize registered;

- (id)init
{
	if ((self = [super init])) {
		registered = [Preferences registeredToGrowl];
	}

	return self;
}

- (void)dealloc
{
	[growl drain];
	[lastClickedContext drain];
	
	[super dealloc];
}

- (void)registerToGrowl
{
	if (growl) return;
	
	growl = [TinyGrowlClient new];
	growl.delegate = self;
	
	if (registered == NO) {
		growl.allNotifications = [NSArray array];
		growl.defaultNotifications = growl.allNotifications;
		
		[growl registerApplication];
	}
	
	growl.allNotifications = [NSArray arrayWithObjects:
							  TXTLS(@"GROWL_MSG_LOGIN"), TXTLS(@"GROWL_MSG_KICKED"), 
							  TXTLS(@"GROWL_MSG_INVITED"), TXTLS(@"GROWL_MSG_NEW_TALK"), 
							  TXTLS(@"GROWL_MSG_TALK_MSG"), TXTLS(@"GROWL_MSG_HIGHLIGHT"), 
							  TXTLS(@"GROWL_MSG_DISCONNECT"), TXTLS(@"GROWL_MSG_TALK_NOTICE"), 
							  TXTLS(@"GROWL_MSG_CHANNEL_MSG"), TXTLS(@"GROWL_MSG_CHANNEL_NOTICE"), 
							  TXTLS(@"GROWL_ADDRESS_BOOK_MATCH"), nil];
	
	growl.defaultNotifications = growl.allNotifications;
	[growl registerApplication];
}

- (void)notify:(GrowlNotificationType)type title:(NSString *)title desc:(NSString *)desc context:(id)context
{
	if ([Preferences growlEnabledForEvent:type] == NO) return;
	
	NSString *kind = nil;
	NSInteger priority = 0;
	
	BOOL sticky = [Preferences growlStickyForEvent:type];
	
	switch (type) {
		case GROWL_ADDRESS_BOOK_MATCH:
			priority = 1;
			kind = TXTLS(@"GROWL_ADDRESS_BOOK_MATCH");
			title = TXTLS(@"GROWL_MSG_ADDRESS_BOOK_MATCH_TITLE");
			break;
		case GROWL_HIGHLIGHT:
			priority = 1;
			kind =  TXTLS(@"GROWL_MSG_HIGHLIGHT");
			title = TXTFLS(@"GROWL_MSG_HIGHLIGHT_TITLE", title);
			break;
		case GROWL_NEW_TALK:
			priority = 1;
			kind =  TXTLS(@"GROWL_MSG_NEW_TALK");
			title = TXTLS(@"GROWL_MSG_NEW_TALK_TITLE");
			break;
		case GROWL_CHANNEL_MSG:
			kind =  TXTLS(@"GROWL_MSG_CHANNEL_MSG");
			break;
		case GROWL_CHANNEL_NOTICE:
			kind =  TXTLS(@"GROWL_MSG_CHANNEL_NOTICE");
			title = TXTFLS(@"GROWL_MSG_CHANNEL_NOTICE_TITLE", title);
			break;
		case GROWL_TALK_MSG:
			kind =  TXTLS(@"GROWL_MSG_TALK_MSG");
			title = TXTLS(@"GROWL_MSG_TALK_MSG_TITLE");
			break;
		case GROWL_TALK_NOTICE:
			kind =  TXTLS(@"GROWL_MSG_TALK_NOTICE");
			title = TXTLS(@"GROWL_MSG_TALK_NOTICE_TITLE");
			break;
		case GROWL_KICKED:
			kind =  TXTLS(@"GROWL_MSG_KICKED");
			title = TXTFLS(@"GROWL_MSG_KICKED_TITLE", title);
			break;
		case GROWL_INVITED:
			kind =  TXTLS(@"GROWL_MSG_INVITED");
			title = TXTFLS(@"GROWL_MSG_INVITED_TITLE", title);
			break;
		case GROWL_LOGIN:
			kind =  TXTLS(@"GROWL_MSG_LOGIN");
			title = TXTFLS(@"GROWL_MSG_LOGIN_TITLE", title);
			break;
		case GROWL_DISCONNECT:
			kind =  TXTLS(@"GROWL_MSG_DISCONNECT");
			title = TXTFLS(@"GROWL_MSG_DISCONNECT_TITLE", title);
			break;
	}
	
	[growl notifyWithType:kind title:title description:desc clickContext:context sticky:sticky priority:priority icon:nil];
}

- (void)tinyGrowlClient:(TinyGrowlClient *)sender didClick:(id)context
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if ((now - lastClickedTime) < CLICK_INTERVAL) {
		if (lastClickedContext && [lastClickedContext isEqual:context]) {
			return;
		}
	}
	
	lastClickedTime = now;
	
	[lastClickedContext drain];
	lastClickedContext = [context retain];
	
	if (registered == NO) {
		registered = YES;
		
		[Preferences setRegisteredToGrowl:YES];
	}
	
	[owner.window makeKeyAndOrderFront:nil];
	
	[NSApp activateIgnoringOtherApps:YES];
	
	if ([context isKindOfClass:[NSString class]]) {
		NSArray *ary = [context componentsSeparatedByString:@" "];
		
		if (ary.count >= 2) {
			NSInteger uid = [ary integerAtIndex:0];
			NSInteger cid = [ary integerAtIndex:1];
			
			IRCClient  *u = [owner findClientById:uid];
			IRCChannel *c = [owner findChannelByClientId:uid channelId:cid];
			
			if (c) {
				[owner select:c];
			} else if (u) {
				[owner select:u];
			}
		} else if (ary.count == 1) {
			NSInteger uid = [ary integerAtIndex:0];
			
			IRCClient *u = [owner findClientById:uid];
			
			if (u) {
				[owner select:u];
			}
		}
	}
}

- (void)tinyGrowlClient:(TinyGrowlClient *)sender didTimeOut:(id)context
{
	if (registered == NO) {
		registered = YES;
		
		[Preferences setRegisteredToGrowl:YES];
	}
}

@end