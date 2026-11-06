import 'shoe.dart';

class CartItem {
  final Shoe shoe;
  final int size;
  final String colorway;
  final int quantity;

  const CartItem({
    required this.shoe,
    required this.size,
    required this.colorway,
    this.quantity = 1,
  });

  /// The same shoe in a different size or colorway is a separate cart line.
  String get key => '${shoe.id}|$size|$colorway';

  double get total => shoe.price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    shoe: shoe,
    size: size,
    colorway: colorway,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toJson() => {
    'shoeId': shoe.id,
    'size': size,
    'colorway': colorway,
    'quantity': quantity,
  };
}
