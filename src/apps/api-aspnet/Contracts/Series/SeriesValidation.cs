using System.ComponentModel.DataAnnotations;

namespace Appd.Api.Contracts.Series;

internal static class SeriesValidation
{
    public static IEnumerable<ValidationResult> ValidateStringList(List<string>? values, string propertyName)
    {
        if (values is null)
        {
            yield return new ValidationResult($"{propertyName} is required.", [propertyName]);
            yield break;
        }

        foreach (var result in ValidateListItems(values, propertyName))
        {
            yield return result;
        }
    }

    public static IEnumerable<ValidationResult> ValidateOptionalStringList(List<string>? values, string propertyName)
    {
        if (values is null)
        {
            yield break;
        }

        foreach (var result in ValidateListItems(values, propertyName))
        {
            yield return result;
        }
    }

    public static IEnumerable<ValidationResult> ValidateObject(object value, string memberName)
    {
        var nestedResults = new List<ValidationResult>();
        var nestedContext = new ValidationContext(value);
        Validator.TryValidateObject(value, nestedContext, nestedResults, true);

        foreach (var result in nestedResults)
        {
            if (result.MemberNames.Any())
            {
                var members = result.MemberNames.Select(member => $"{memberName}.{member}").ToArray();
                yield return new ValidationResult(result.ErrorMessage, members);
            }
            else
            {
                yield return new ValidationResult(result.ErrorMessage, [memberName]);
            }
        }
    }

    private static IEnumerable<ValidationResult> ValidateListItems(List<string> values, string propertyName)
    {
        if (values.Any(string.IsNullOrWhiteSpace))
        {
            yield return new ValidationResult($"{propertyName} values must be non-empty strings.", [propertyName]);
        }

        if (values.Any(item => item is { Length: > 50 }))
        {
            yield return new ValidationResult($"{propertyName} values must be at most 50 characters.", [propertyName]);
        }

        var distinctCount = values
            .Select(value => value.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Count();

        if (distinctCount != values.Count)
        {
            yield return new ValidationResult($"{propertyName} values must be unique.", [propertyName]);
        }
    }
}
