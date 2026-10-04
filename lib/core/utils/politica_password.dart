import 'dart:convert';

import 'validadores.dart';

/// The one password policy (register and change password): min 8 and max 64
/// characters (code points, so an emoji counts once), at most 72 UTF-8 bytes
/// (the bcrypt limit), one uppercase, one digit.
enum RequisitoPassword {
  minimo('Al menos 8 caracteres'),
  maximo('Máximo 64 caracteres'),
  maximoBytes('Máximo 72 bytes: los emojis y acentos ocupan más de uno'),
  mayuscula('Al menos una mayúscula'),
  numero('Al menos un número');

  final String texto;

  const RequisitoPassword(this.texto);
}

const int _minimoCaracteres = 8;
const int _maximoCaracteres = 64;
const int _maximoBytes = 72;

/// The requirements [password] does not meet, in display order.
List<RequisitoPassword> requisitosIncumplidos(String password) {
  final caracteres = password.runes.length;
  return [
    if (caracteres < _minimoCaracteres) RequisitoPassword.minimo,
    if (caracteres > _maximoCaracteres) RequisitoPassword.maximo,
    if (caracteres <= _maximoCaracteres &&
        utf8.encode(password).length > _maximoBytes)
      RequisitoPassword.maximoBytes,
    if (!password.contains(RegExp('[A-Z]'))) RequisitoPassword.mayuscula,
    if (!password.contains(RegExp('[0-9]'))) RequisitoPassword.numero,
  ];
}

/// Form validator: required, then the first unmet requirement.
String? validarPassword(String? valor) {
  if (valor == null || valor.isEmpty) return Validadores.mensajeObligatorio;
  final incumplidos = requisitosIncumplidos(valor);
  return incumplidos.isEmpty ? null : incumplidos.first.texto;
}
