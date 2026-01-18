import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class OtpResponse {
  @JsonKey(name: 'otp_expires_in')
  final int otpExpiresIn;

  OtpResponse({required this.otpExpiresIn});

  factory OtpResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OtpResponseToJson(this);
}
