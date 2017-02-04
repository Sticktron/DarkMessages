//
//  DebugLog.h
//  NSLog wrapper
//
//  DebugLog(msg)			print Class, Selector, msg
//  DebugLog0				print Class, Selector
//  DebugLogMore(msg)		print Filename, Line, Signature, msg
//  DebugLogC(msg)			print msg
//
//  -Sticktron
//
//

#ifdef DEBUG

// Default Prefix
#ifndef DEBUG_PREFIX
	#define DEBUG_PREFIX @"[DebugLog]"
#endif

#define DebugLog(s, ...) \
	NSLog(@"%@ >> %@", DEBUG_PREFIX, \
		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
	)

// #define DebugLog(s, ...) \
// 	NSLog(@"%@ %@::%@ >> %@", DEBUG_PREFIX, \
// 		NSStringFromClass([self class]), \
// 		NSStringFromSelector(_cmd), \
// 		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
// 	)

// #define DebugLog0 \
// 	NSLog(@"%@ %@::%@", DEBUG_PREFIX, \
// 		NSStringFromClass([self class]), \
// 		NSStringFromSelector(_cmd) \
// 	)

// #define DebugLogC(s, ...) \
// 	NSLog(@"%@ >> %@", DEBUG_PREFIX, \
// 		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
// 	)

// #define DebugLogMore(s, ...) \
// 	NSLog(@"%@ %s:(%d) >> %s >> %@", \
// 		DEBUG_PREFIX, \
// 		[[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
// 		__LINE__, \
// 		__PRETTY_FUNCTION__, \
// 		[NSString stringWithFormat:(s), \
// 		##__VA_ARGS__] \
// 	)

// #define UA_SHOW_VIEW_BORDERS YES
// #define UA_showDebugBorderForViewColor(view, color) if (UA_SHOW_VIEW_BORDERS) { view.layer.borderColor = color.CGColor; view.layer.borderWidth = 1.0; }
// #define UA_showDebugBorderForView(view) UA_showDebugBorderForViewColor(view, [UIColor colorWithWhite:0.0 alpha:0.25])

#else

#define DebugLog(s, ...)
// #define DebugLog0
// #define DebugLogC(s, ...)
// #define DebugLogMore(s, ...)

#endif
