class Validators {
  static String? validateDni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El DNI es obligatorio';
    }
    if (value.trim().length != 8 || int.tryParse(value) == null) {
      return 'El DNI debe tener 8 dígitos numéricos';
    }
    return null;
  }

  static String? validateEmployeeCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de empleado es obligatorio';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  static String? validateAmount(String? value, double min, double max) {
    if (value == null || value.trim().isEmpty) {
      return 'El monto es obligatorio';
    }
    final amt = double.tryParse(value);
    if (amt == null) {
      return 'Ingrese un monto numérico válido';
    }
    if (amt < min || amt > max) {
      return 'El monto debe estar entre S/ $min y S/ $max';
    }
    return null;
  }
}
