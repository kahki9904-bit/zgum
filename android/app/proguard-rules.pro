-keep class com.kakao.vectormap.** { *; }
-keep interface com.kakao.vectormap.** { *; }
-keep class com.kakao.maps.** { *; }
-keep interface com.kakao.maps.** { *; }
-dontwarn com.kakao.vectormap.**
-dontwarn com.kakao.maps.**

-keep class com.dexterous.** { *; }

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
