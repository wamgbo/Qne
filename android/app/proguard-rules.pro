# 忽略 javax.imageio 相關的缺失警告
-dontwarn javax.imageio.**
-dontwarn java.awt.**
-keep class javax.imageio.** { *; }

# 針對你報錯中提到的具體類別
-dontwarn com.github.jaiimageio.**