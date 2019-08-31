//
//  DisplayData.h
//  DisplayBed
//
//  Created by Luca Attanasio on 02/10/2017.
//  Copyright © 2017 Luca Attanasio. All rights reserved.
//

#ifndef DisplayData_h
#define DisplayData_h


#endif /* DisplayData_h */

#import <Foundation/Foundation.h>

typedef struct {
    uint32_t modeNumber;
    uint32_t flags;
    uint32_t width;
    uint32_t height;
    uint32_t depth;
    uint8_t unknown[170];
    uint16_t freq;
    uint8_t more_unknown[16];
    float density;
} CGSDisplayMode
;

extern AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);
extern io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID);
extern CGError CGSConfigureDisplayEnabled(CGDisplayConfigRef, CGDirectDisplayID, bool);
extern CGDisplayErr CGSGetDisplayList(CGDisplayCount maxDisplays, CGDirectDisplayID * onlineDspys, CGDisplayCount * dspyCnt);
extern void CGSGetNumberOfDisplayModes(CGDirectDisplayID display, int *nModes);
extern void CGSGetDisplayModeDescriptionOfLength(CGDirectDisplayID display, int idx, CGSDisplayMode *mode, int length);
extern CGError CGSGetDisplayPixelEncodingOfLength(CGDirectDisplayID displayID, char *pixelEncoding, size_t length);
extern CGError CGSConfigureDisplayMode(CGDisplayConfigRef config, CGDirectDisplayID display, int modeNum);
extern CGError CGSGetCurrentDisplayMode(CGDirectDisplayID display, int *modeNum);

@interface DisplayData : NSObject
{
    CGSDisplayMode mode;
    CGDirectDisplayID display;
    float brightness;
}
@property CGSDisplayMode mode;
@property CGDirectDisplayID display;
@property float brightness;
@end
