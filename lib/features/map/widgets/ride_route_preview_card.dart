import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_sharing_user_app/common_widgets/osm_route_map_widget.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

/// Card shown when the captain taps the "eye" on a ride request.
/// Two tabs on top of an OpenStreetMap map:
///  1. captain -> customer pickup
///  2. customer pickup -> trip destination
class RideRoutePreviewCard extends StatefulWidget {
  final LatLng captain;
  final LatLng pickup;
  final LatLng? destination;
  final String? pickupAddress;
  final String? destinationAddress;

  const RideRoutePreviewCard({
    super.key,
    required this.captain,
    required this.pickup,
    this.destination,
    this.pickupAddress,
    this.destinationAddress,
  });

  static Future<void> show(BuildContext context, {
    required LatLng captain, required LatLng pickup, LatLng? destination,
    String? pickupAddress, String? destinationAddress,
  }) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
        child: RideRoutePreviewCard(
          captain: captain, pickup: pickup, destination: destination,
          pickupAddress: pickupAddress, destinationAddress: destinationAddress,
        ),
      ),
    );
  }

  @override
  State<RideRoutePreviewCard> createState() => _RideRoutePreviewCardState();
}

class _RideRoutePreviewCardState extends State<RideRoutePreviewCard> {
  int _tab = 0;

  Widget _tabButton(int index, String label, IconData icon) {
    final selected = _tab == index;
    final primary = Theme.of(context).primaryColor;
    return Expanded(
      child: InkWell(
        key: Key('route_preview_tab_$index'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? Colors.white : primary),
            const SizedBox(width: 6),
            Flexible(child: Text(
              label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: textSemiBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: selected ? Colors.white : primary,
              ),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDestination = widget.destination != null;
    final toCustomer = _tab == 0 || !hasDestination;
    final from = toCustomer ? widget.captain : widget.pickup;
    final to = toCustomer ? widget.pickup : widget.destination!;
    final address = toCustomer ? widget.pickupAddress : widget.destinationAddress;

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text('view_both_locations'.tr, style: textBold)),
          InkWell(
            key: const Key('route_preview_close'),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close)),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            _tabButton(0, 'route_to_customer'.tr, Icons.directions_car_filled_outlined),
            if (hasDestination) _tabButton(1, 'customer_trip_route'.tr, Icons.alt_route),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        OsmRouteMap(
          key: ValueKey('osm_tab_${toCustomer ? 0 : 1}'),
          from: from, to: to, height: 300,
        ),

        if (address != null && address.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            Icon(Icons.location_on, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Expanded(child: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
          ]),
        ],
      ]),
    );
  }
}
