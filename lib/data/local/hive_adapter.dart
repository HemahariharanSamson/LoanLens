import 'package:hive/hive.dart';
import '../models/loan_model.dart';
import '../models/user_profile.dart';

/// Hive TypeAdapter for LoanModel
class LoanModelAdapter extends TypeAdapter<LoanModel> {
  @override
  final int typeId = 0;

  @override
  LoanModel read(BinaryReader reader) {
    final firstEmiDateStr = reader.readString();
    final closureDateStr = reader.readString();
    
    return LoanModel(
      id: reader.readString(),
      loanName: reader.readString(),
      lenderName: reader.readString(),
      principalAmount: reader.readDouble(),
      interestRate: reader.readDouble(),
      interestType: reader.readString(),
      emiAmount: reader.readDouble(),
      startDate: DateTime.parse(reader.readString()),
      tenure: reader.readInt(),
      tenureUnit: reader.readString(),
      paymentFrequency: reader.readString(),
      notificationsEnabled: reader.readBool(),
      reminderDaysBefore: reader.readInt(),
      monthsPaidSoFar: reader.readInt(),
      amountPaidSoFar: reader.readDouble(),
      firstEmiDate: firstEmiDateStr.isEmpty ? null : DateTime.parse(firstEmiDateStr),
      status: reader.readString(),
      closureDate: closureDateStr.isEmpty ? null : DateTime.parse(closureDateStr),
      closureAmount: reader.readBool() ? reader.readDouble() : null,
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, LoanModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.loanName);
    writer.writeString(obj.lenderName);
    writer.writeDouble(obj.principalAmount);
    writer.writeDouble(obj.interestRate);
    writer.writeString(obj.interestType);
    writer.writeDouble(obj.emiAmount);
    writer.writeString(obj.startDate.toIso8601String());
    writer.writeInt(obj.tenure);
    writer.writeString(obj.tenureUnit);
    writer.writeString(obj.paymentFrequency);
    writer.writeBool(obj.notificationsEnabled);
    writer.writeInt(obj.reminderDaysBefore);
    writer.writeInt(obj.monthsPaidSoFar);
    writer.writeDouble(obj.amountPaidSoFar);
    writer.writeString(obj.firstEmiDate?.toIso8601String() ?? '');
    writer.writeString(obj.status);
    writer.writeString(obj.closureDate?.toIso8601String() ?? '');
    writer.writeBool(obj.closureAmount != null);
    if (obj.closureAmount != null) {
      writer.writeDouble(obj.closureAmount!);
    }
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}

/// Hive TypeAdapter for UserProfile
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

  @override
  UserProfile read(BinaryReader reader) {
    final hasName = reader.readBool();
    return UserProfile(
      name: hasName ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeBool(obj.name != null && obj.name!.isNotEmpty);
    if (obj.name != null && obj.name!.isNotEmpty) {
      writer.writeString(obj.name!);
    }
  }
}


