using System.ComponentModel.DataAnnotations;

namespace SeriesCatalog.WebApi.Common.Validation;

public sealed class DataAnnotationsValidationFilter<TRequest> : IEndpointFilter where TRequest : class
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var request = context.Arguments.OfType<TRequest>().FirstOrDefault();
        if (request is null)
        {
            return await next(context);
        }

        var validationResults = new List<ValidationResult>();
        var validationContext = new ValidationContext(request);
        var isValid = Validator.TryValidateObject(request, validationContext, validationResults, true);

        if (isValid)
        {
            return await next(context);
        }

        var errors = validationResults
            .Where(result => result != ValidationResult.Success)
            .SelectMany(result =>
            {
                var members = result!.MemberNames.Any() ? result.MemberNames : ["request"];
                return members.Select(member => new
                {
                    Member = member,
                    Message = result.ErrorMessage ?? "The request is invalid."
                });
            })
            .GroupBy(item => item.Member, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => group.Select(item => item.Message).Distinct().ToArray(),
                StringComparer.OrdinalIgnoreCase);

        return TypedResults.ValidationProblem(errors);
    }
}

