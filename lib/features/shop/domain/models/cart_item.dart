import 'shoe.dart';

class CartItem {
  final Shoe shoe;
  int quantity;

  CartItem({required this.shoe, this.quantity = 1});

  double get total => shoe.price * quantity;
}
