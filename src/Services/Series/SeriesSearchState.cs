namespace BlazorMigration.Services.Series;

public sealed class SeriesSearchState
{
    public event Action? SearchChanged;

    public string SearchTerm { get; private set; } = string.Empty;

    public void SetSearchTerm(string? value)
    {
        var normalizedValue = value?.Trim() ?? string.Empty;

        if (string.Equals(SearchTerm, normalizedValue, StringComparison.Ordinal))
        {
            return;
        }

        SearchTerm = normalizedValue;
        SearchChanged?.Invoke();
    }
}