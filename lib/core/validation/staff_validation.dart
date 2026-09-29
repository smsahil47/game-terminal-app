String? customerNameError(String input) {
  final name=input.trim();
  if(name.isEmpty)return 'Customer name is required.';
  if(name.length<2)return 'Name must be at least 2 characters.';
  if(name.length>80)return 'Name is too long (max 80 characters).';
  if(RegExp(r'^\d+$').hasMatch(name))return 'Name cannot be only numbers.';
  if(!RegExp(r'\p{L}',unicode:true).hasMatch(name))return 'Enter a valid name.';
  return null;
}
String? indianPhoneError(String? input) {
  final phone=(input??'').trim();
  if(phone.isEmpty)return null;
  if(!RegExp(r'^\d+$').hasMatch(phone))return 'Phone must contain only digits (10 numbers).';
  if(phone.length!=10)return 'Phone must be exactly 10 digits.';
  if(!RegExp(r'^[6-9]').hasMatch(phone))return 'Enter a valid mobile number starting with 6, 7, 8, or 9.';
  return null;
}
String? gameTitleError(String input) {
  final game=input.trim();
  if(game.isEmpty)return 'Select or enter a game.';
  if(game.length<2 || game.length>80)return 'Game title must be 2 to 80 characters.';
  return null;
}
