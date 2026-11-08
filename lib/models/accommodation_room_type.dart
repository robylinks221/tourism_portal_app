class AccommodationRoomType {
  const AccommodationRoomType({required this.id, required this.name, required this.pricePerNight, required this.currency, required this.maxOccupancy, required this.quantity, required this.isActive, this.description, this.bedType});
  final int id, maxOccupancy, quantity;
  final String name, currency;
  final String? description, bedType;
  final double pricePerNight;
  final bool isActive;
  factory AccommodationRoomType.fromJson(Map<String,dynamic> j) => AccommodationRoomType(
    id: int.tryParse('${j['id']}') ?? 0,
    name: '${j['name'] ?? ''}',
    description: j['description']?.toString(),
    pricePerNight: double.tryParse('${j['price_per_night']}') ?? 0,
    currency: '${j['currency'] ?? 'USD'}',
    maxOccupancy: int.tryParse('${j['max_occupancy']}') ?? 1,
    bedType: j['bed_type']?.toString(),
    quantity: int.tryParse('${j['quantity']}') ?? 0,
    isActive: j['is_active'] == true || j['is_active'] == 1,
  );
}
