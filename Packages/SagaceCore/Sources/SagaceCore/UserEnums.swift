/// Énumérations de l'état utilisateur, stockées par SagaceData (valeurs brutes stables : ne jamais les renommer).

/// Tri d'une fiche dans le feed.
public enum Sorting: String, Codable, Sendable, CaseIterable {
    /// "Je savais" : la fiche ne revient plus.
    case known
    /// "À retenir" : la fiche entre en révision.
    case toLearn
}

public enum AgeRange: String, Codable, Sendable, CaseIterable {
    case age13to17, age18to24, age25to34, age35to44, age45to54, age55plus
}

public enum AttributionSource: String, Codable, Sendable, CaseIterable {
    case tiktok, instagram, facebook, youtube, appStore, webSearch, friend, other
}

public enum LearningGoal: String, Codable, Sendable, CaseIterable {
    case ecrireTravail, parlerAssurance, examen, enfants, curiosite
}

public enum Appearance: String, Codable, Sendable, CaseIterable {
    case automatic, light, dark
}

public enum SoundMode: String, Codable, Sendable, CaseIterable {
    case muted, effects, effectsAndAmbience
}

public enum PracticeMode: String, Codable, Sendable, CaseIterable {
    case motJuste, paronymes, justeOuFautif, passePartout, sens, devine
    case rush, sprint, perfection
    case levelTest, review
}

public enum Skill: String, Codable, Sendable, CaseIterable {
    case sens, usage, choixDuMot
}

public enum ReminderSource: String, Codable, Sendable, CaseIterable {
    case fichesDuJour, aRetenir, collection, famille
}

public enum WidgetKind: String, Codable, Sendable, CaseIterable {
    case ficheDuJour, revision, serie, ecranVerrouille
}

public enum RefreshRate: String, Codable, Sendable, CaseIterable {
    case hourly, twiceDaily, daily
}
