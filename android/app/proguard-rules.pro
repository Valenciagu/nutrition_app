# Reglas extra de R8 para release. El plugin de Gradle de Flutter ya activa
# R8 (minify) y la reducción de recursos en release y agrega este archivo
# automáticamente si existe — no hace falta declararlo en build.gradle.kts.

# flutter_local_notifications (Épica 12) guarda las notificaciones
# programadas serializadas con Gson y su v18 no trae reglas propias: sin
# esto, R8 borra/renombra los modelos y la app crashea SOLO en release al
# programar o al reprogramar tras un reinicio ("Missing type parameter").
# Reglas tomadas de la documentación del propio plugin.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
