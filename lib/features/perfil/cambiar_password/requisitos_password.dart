import 'dart:convert';

/// Password policy shared with the backend (min 8, max 64 characters and at
/// most 72 bytes, one uppercase, one digit). Kept in the feature on purpose.
enum RequisitoPassword {
  minimo('Al menos 8 caracteres'),
  maximo('Máximo 64 caracteres'),
  mayuscula('Al menos una mayúscula'),
  numero('Al menos un número');

  final String texto;

  const RequisitoPassword(this.texto);
}

const int _minimoCaracteres = 8;
const int _maximoCaracteres = 64;
const int _maximoBytes = 72;

/// The requirements [password] does not meet, in display order.
List<RequisitoPassword> requisitosIncumplidos(String password) => [
      if (password.length < _minimoCaracteres) RequisitoPassword.minimo,
      if (password.length > _maximoCaracteres ||
          utf8.encode(password).length > _maximoBytes)
        RequisitoPassword.maximo,
      if (!password.contains(RegExp('[A-Z]'))) RequisitoPassword.mayuscula,
      if (!password.contains(RegExp('[0-9]'))) RequisitoPassword.numero,
    ];
