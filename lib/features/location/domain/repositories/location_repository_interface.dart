import 'package:get/get_connect/http/src/response/response.dart';
import 'package:ride_sharing_user_app/map/app_map.dart';
import 'package:ride_sharing_user_app/interface/repository_interface.dart';

abstract class LocationRepositoryInterface implements RepositoryInterface{
  Future<Response> getZone(String lat, String lng);
  Future<bool?> saveUserZoneId(String zoneId);
  Future<Response> getAddressFromGeocode(LatLng? latLng);
  Future<Response> searchLocation(String text);
  Future<Response> storeLastLocationApi(String lat, String lng, String zoneID);
}