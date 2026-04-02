using System.ComponentModel.DataAnnotations;

namespace Appd.Api.Contracts.Series;

public sealed class CreateSeriesRequest
{
	[Required]
	[StringLength(50, MinimumLength = 1)]
	public string Title { get; init; } = string.Empty;

	[Required]
	[StringLength(50, MinimumLength = 1)]
	public string Genre { get; init; } = string.Empty;

	[Range(1, 9999)]
	public int ReleaseYear { get; init; }
}
