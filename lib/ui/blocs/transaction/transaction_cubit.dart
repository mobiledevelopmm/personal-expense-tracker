import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/transaction_service.dart';
import '../../../models/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionService _service;
  StreamSubscription<List<ExpenseTransaction>>? _subscription;

  TransactionCubit(this._service) : super(const TransactionState());

  void listenToTransactions() {
    emit(state.copyWith(
      status: TransactionStatus.loading,
      clearError: true,
    ));

    _subscription?.cancel();

    _subscription = _service.watchTransactions().listen(
          (transactions) {
        emit(state.copyWith(
          status: TransactionStatus.success,
          transactions: transactions,
          clearError: true,
        ));
      },
      onError: (Object error) {
        emit(state.copyWith(
          status: TransactionStatus.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }


  Future<void> addTransaction(
      ExpenseTransaction transaction,
      ) async {
    try {
      await _service
          .addTransaction(transaction)
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: error.toString(),
      ));
      rethrow;
    }
  }


  Future<void> deleteTransaction(String id) async {
    try {
      await _service.deleteTransaction(id);
    } catch (error) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: error.toString(),
      ));
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}