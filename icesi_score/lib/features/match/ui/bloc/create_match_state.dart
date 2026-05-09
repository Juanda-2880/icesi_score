import '../../domain/entities/team.dart';
import '../../domain/entities/league.dart';

class CreateMatchFormData {
  final List<Team> allTeams;
  final List<League> leagues;
  final String selectedSport;

  const CreateMatchFormData({
    required this.allTeams,
    required this.leagues,
    this.selectedSport = 'FOOTBALL',
  });

  List<Team> get filteredTeams =>
      allTeams.where((t) => t.sport == selectedSport).toList();

  CreateMatchFormData withSport(String sport) => CreateMatchFormData(
        allTeams: allTeams,
        leagues: leagues,
        selectedSport: sport,
      );
}

abstract class CreateMatchState {
  const CreateMatchState();
}

class CreateMatchFormLoadingState extends CreateMatchState {
  const CreateMatchFormLoadingState();
}

class CreateMatchFormReadyState extends CreateMatchState {
  final CreateMatchFormData formData;
  const CreateMatchFormReadyState(this.formData);
}

class CreateMatchSubmittingState extends CreateMatchState {
  final CreateMatchFormData formData;
  const CreateMatchSubmittingState(this.formData);
}

class CreateMatchSuccessState extends CreateMatchState {
  const CreateMatchSuccessState();
}

// formData is null when the initial data load failed (show retry).
// formData is non-null when submission failed (keep form visible).
class CreateMatchFailureState extends CreateMatchState {
  final String message;
  final CreateMatchFormData? formData;
  const CreateMatchFailureState(this.message, [this.formData]);
}
