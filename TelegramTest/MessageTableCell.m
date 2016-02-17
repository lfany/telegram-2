//
//  MessageTableCell.m
//  Telegram P-Edition
//
//  Created by Dmitry Kondratyev on 1/26/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "MessageTableCell.h"
#import "MessageTableCellTextView.h"
#import "TGMessageViewSender.h"
@interface MessageTableCell()<NSMenuDelegate>

@end

@implementation MessageTableCell

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if(self) {
//        self.wantsLayer = YES;
//        self.layer.backgroundColor = [NSColor whiteColor].CGColor;
//        self.layer.opaque = NO;
    }
    return self;
}

- (void)setItem:(MessageTableItem *)item {
    self->_item = item;
    
    if(item.message && ( item.message.dstate != DeliveryStateNormal && item.messageSender == nil )) {
        item.messageSender = [SenderItem senderForMessage:item.message];
        item.messageSender.tableItem = item;
        if(item.messageSender.state == MessageStateWaitSend) {
            [item.messageSender send];
        }
    }
    
    if(item.message.isChannelMessage && item.message.from_id == 0 && !item.message.isViewed) {
        if(![item.message isKindOfClass:[TL_localMessageService class]]) {
            item.message.viewed = YES;
            [TGMessageViewSender addItem:item];
        }
        
    }
    
}

- (void)resizeAndRedraw {
    [self setItem:self.item];
}


-(void)addScrollEvent {
    id clipView = [[self.item.table enclosingScrollView] contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didScrolledTableView:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:clipView];

}

-(void)removeScrollEvent {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)_didScrolledTableView:(NSNotification *)notification {
    
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)rightMouseDown:(NSEvent *)theEvent {
    
    if(self.item.messageSender != nil || self.item.message.n_id > TGMINFAKEID) {
        [super rightMouseDown:theEvent];
        return;
    }
    
    NSMenu *contextMenu = [self contextMenu];
    
    if(contextMenu && self.messagesViewController.state == MessagesViewControllerStateNone) {
        
        contextMenu.delegate = self;
        
        [NSMenu popUpContextMenu:contextMenu withEvent:theEvent forView:self];
    } else {
        [super rightMouseDown:theEvent];
    }
}


- (void)menuWillOpen:(NSMenu *)menu {
    self.layer.backgroundColor =  NSColorFromRGB(0xf7f7f7).CGColor;
    [self _didChangeBackgroundColorWithAnimation:nil toColor:NSColorFromRGB(0xf7f7f7)];
}


- (void)menuDidClose:(NSMenu *)menu {
    self.layer.backgroundColor = NSColorFromRGB(0xffffff).CGColor;
    [self _didChangeBackgroundColorWithAnimation:nil toColor:NSColorFromRGB(0xffffff)];
}


- (NSMenu *)contextMenu {
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Context"];
    
    [self.defaultMenuItems enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [menu addItem:item];
    }];
    
    return menu;
}

-(NSArray *)defaultMenuItems {
    
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    
    weak();
    
    if([self.item.message.conversation canSendMessage]) {
        
        if(self.item.message.conversation.type != DialogTypeSecretChat || self.item.message.conversation.encryptedChat.encryptedParams.layer >= 45) {
            [items addObject:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Context.Reply", nil) withBlock:^(id sender) {
                
                [weakSelf.messagesViewController addReplayMessage:weakSelf.item.message animated:YES];
                
            }]];
        }
    }
    
    if([self.item canShare]) {
        
        NSArray *shareServiceItems = [NSSharingService sharingServicesForItems:@[self.item.shareObject]];
        
        NSMenu *shareMenu = [[NSMenu alloc] initWithTitle:@"Share"];
        
        
        for (NSSharingService *currentService in shareServiceItems) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:currentService.title action:@selector(selectedSharingServiceFromMenuItem:) keyEquivalent:@""];
            item.image = currentService.image;
            item.representedObject = currentService;
            [shareMenu addItem:item];
        }
        
        NSMenuItem *shareSubItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Context.Share",nil) withBlock:nil];
        
        [shareSubItem setSubmenu:shareMenu];
        
        [items addObject:shareSubItem];
        
        [items addObject:[NSMenuItem separatorItem]];
        
    }
    
    
    if(self.item.message.conversation.type != DialogTypeSecretChat) {
        [items addObject:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Context.Forward", nil) withBlock:^(id sender) {
            
            [weakSelf.messagesViewController setState:MessagesViewControllerStateNone];
            [weakSelf.messagesViewController unSelectAll:NO];
            
            
            
            [weakSelf.messagesViewController setSelectedMessage:weakSelf.item selected:YES];
            
            
            [weakSelf.messagesViewController showForwardMessagesModalView];
            
            
        }]];
    }
    
    if([MessagesViewController canDeleteMessages:@[self.item.message] inConversation:self.item.message.conversation]) {
        [items addObject:[NSMenuItem menuItemWithTitle:NSLocalizedString(@"Context.Delete", nil) withBlock:^(id sender) {
            
            [weakSelf.messagesViewController setState:MessagesViewControllerStateNone];
            [weakSelf.messagesViewController unSelectAll:NO];
            
            [weakSelf.messagesViewController setSelectedMessage:weakSelf.item selected:YES];
            
            [weakSelf.messagesViewController deleteSelectedMessages];
            
            
        }]];
    }
    
    return items;
    
}

-(void)mouseDown:(NSEvent *)theEvent {
    if(theEvent.clickCount == 2 && self.messagesViewController.state == MessagesViewControllerStateNone) {
        
        BOOL accept = ![self mouseInText:theEvent];;
        
        MTLog(@"message_id:%d",self.item.message.n_id);
        
        if(accept && self.item.message.n_id < TGMINFAKEID && self.item.message.n_id > 0)
            [_messagesViewController addReplayMessage:self.item.message animated:YES];
    }
    
    
    [super mouseDown:theEvent];
}


-(void)clearSelection {
    
}

-(BOOL)mouseInText:(NSEvent *)theEvent {
    return NO;
}


- (void)copy:(id)sender {
    
    if(![self.item.message.media isKindOfClass:[TL_messageMediaEmpty class]]) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:[NSArray arrayWithObject:[NSURL fileURLWithPath:mediaFilePath(self.item.message)]]];
    }
}

-(void)_didChangeBackgroundColorWithAnimation:(POPBasicAnimation *)anim toColor:(NSColor *)toColor {
    
}



@end
