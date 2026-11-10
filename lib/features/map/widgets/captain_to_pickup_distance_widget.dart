import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_sharing_user_app/features/map/widgets/ride_route_preview_card.dart';
import 'package:ride_sharing_user_app/helper/pickup_distance_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

/// Shows the distance between the captain's current location and the
/// customer's pickup location, with an "eye" button that opens both
/// locations (captain -> customer) on the map.
class CaptainToPickupDistanceWidget extends StatefulWidget {
  final TripDetail rideRequest;
  const CaptainToPickupDistanceWidget({super.key, required this.rideRequest});

  @override
  State<CaptainToPickupDistanceWidget> createState() => _CaptainToPickupDistanceWidgetState();
}

class _CaptainToPickupDistanceWidgetState extends State<CaptainToPickupDistanceWidget> {
  Position? _captain;

  @override
  void initState() {
    super.initState();
    _loadCaptainLocation();
  }

  Future<void> _loadCaptainLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (mounted && position != null) {
        setState(() => _captain = position);
      }
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      if (mounted) {
        setState(() => _captain = position);
      }
    } catch (_) {
      // Keep whatever we have (last known) or fall back to the estimated distance.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = PickupDistanceHelper.parseGeoJson(widget.rideRequest.pickupCoordinates?.coordinates);
    final captain = _captain;
    final hasBoth = pickup != null && captain != null;

    String distanceText;
    if (hasBoth) {
      distanceText = PickupDistanceHelper.format(
        PickupDistanceHelper.distanceKm(captain.latitude, captain.longitude, pickup.lat, pickup.lng),
      );
    } else {
      distanceText = '${widget.rideRequest.estimatedDistance?.toStringAsFixed(2) ?? '--'} Km';
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('${'distance'.tr}: ${DateConverter.ltrIsolate(distanceText)}', style: textRegular.copyWith(
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        fontSize: Dimensions.fontSizeSmall,
      )),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      InkWell(
        key: const Key('captain_pickup_eye_button'),
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (!hasBoth) {
            showCustomSnackBar('location_not_available'.tr);
            return;
          }
          final dest = PickupDistanceHelper.parseGeoJson(widget.rideRequest.destinationCoordinates?.coordinates);
          await RideRoutePreviewCard.show(
            context,
            captain: LatLng(captain.latitude, captain.longitude),
            pickup: LatLng(pickup.lat, pickup.lng),
            destination: dest == null ? null : LatLng(dest.lat, dest.lng),
            pickupAddress: widget.rideRequest.pickupAddress,
            destinationAddress: widget.rideRequest.destinationAddress,
          );
        },
        child: Tooltip(
          message: 'view_both_locations'.tr,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.remove_red_eye_outlined, size: 22, color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    ]);
  }
}
