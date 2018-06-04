#ifndef _MYCOMMON_H
#define _MYCOMMON_H


#define SHOW_DEBUG
#ifndef SHOW_DEBUG
	#define hprintf(fmt, ...)
#else
	#ifdef WIN32
		#define hprintf(fmt, ...) printf("[" MODULE_NAME ":%04d] " fmt, __LINE__, __VA_ARGS__)
	#else
		#ifdef __ANDROID__
			#include <android/log.h>
			#define TAG "[A]" // 这个是自定义的LOG的标识
			#define hprintf(fmt,...) __android_log_print(ANDROID_LOG_DEBUG,TAG, "[" MODULE_NAME ":%04d] " fmt, __LINE__,__VA_ARGS__)
		#else
			#define hprintf(fmt, args...) printf("[" MODULE_NAME ":%04d] " fmt, __LINE__, ##args)
		#endif
	#endif
#endif

#endif

