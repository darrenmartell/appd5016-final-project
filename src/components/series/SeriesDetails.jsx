import { useNavigate } from 'react-router-dom';
import { useParams, useOutletContext } from 'react-router-dom';



const SeriesDetails = () => {
  const navigate = useNavigate();
  const { series, isLoading, error } = useOutletContext();
  const { id } = useParams();

  if (error) return <p>An error occurred - {error.message}</p>;
  if (isLoading) return <p>Loading...</p>;

  const seriesItem = series.find(item => item._id === id);

  if (!seriesItem) return <p className="text-red-400">Series not found.</p>;

  return (
    <div className="max-w-4xl mx-auto my-8">
      {/* Header */}
      <div className="bg-zinc-900 rounded-t-lg p-8 border border-zinc-800 border-b-0">
        <h2 className="text-2xl font-bold text-white m-0">
          {seriesItem.title || 'Untitled Series'}
        </h2>
        {(seriesItem.released_year || seriesItem.runtime_minutes) &&
          <div className="mt-2 flex gap-4 text-zinc-300 text-sm">
            {seriesItem.released_year && <span>{seriesItem.released_year}</span>}
            {seriesItem.runtime_minutes && <span>{seriesItem.runtime_minutes} min per episode</span>}
          </div>
        }
        {seriesItem.genres && seriesItem.genres.length > 0 &&
          <div className="mt-3">
            {seriesItem.genres.map((genre, idx) => (
              <span key={idx} className="inline-block bg-red-700 text-white px-3 py-1 rounded-full text-xs font-semibold mr-2 mb-2">{genre}</span>
            ))}
          </div>
        }
      </div>

      {/* Plot Summary */}
      {seriesItem.plot_summary &&
        <div className="bg-zinc-800 px-8 py-6 border-x border-zinc-800 text-zinc-300 leading-relaxed text-base">
          {seriesItem.plot_summary}
        </div>
      }

      {/* Main Content */}
      <div className={`bg-zinc-900 p-8 border border-zinc-800 ${seriesItem.plot_summary ? 'border-t-0' : ''}`}>
        {/* Two-column grid for metadata */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Left Column */}
          <div>
            {/* Cast */}
            {seriesItem.cast && seriesItem.cast.length > 0 &&
              <div className="mb-6">
                <div className="text-xs font-semibold uppercase tracking-wider text-zinc-300 mb-3 pb-1 border-b border-zinc-800">Cast</div>
                <div>
                  {seriesItem.cast.map((member, idx) => (
                    <span key={idx} className="inline-block bg-zinc-800 text-white px-3 py-1 rounded-full text-xs font-semibold mr-2 mb-2 border border-zinc-700">{member}</span>
                  ))}
                </div>
              </div>
            }

            {/* Directors */}
            {seriesItem.directors && seriesItem.directors.length > 0 &&
              <div className="mb-6">
                <div className="text-xs font-semibold uppercase tracking-wider text-zinc-300 mb-3 pb-1 border-b border-zinc-800">Directors</div>
                <div>
                  {seriesItem.directors.map((director, idx) => (
                    <span key={idx} className="inline-block bg-zinc-800 text-white px-3 py-1 rounded-full text-xs font-semibold mr-2 mb-2 border border-zinc-700">{director}</span>
                  ))}
                </div>
              </div>
            }

            {/* Producers */}
            {seriesItem.producers && seriesItem.producers.length > 0 &&
              <div className="mb-6">
                <div className="text-xs font-semibold uppercase tracking-wider text-zinc-300 mb-3 pb-1 border-b border-zinc-800">Producers</div>
                <div>
                  {seriesItem.producers.map((producer, idx) => (
                    <span key={idx} className="inline-block bg-zinc-800 text-white px-3 py-1 rounded-full text-xs font-semibold mr-2 mb-2 border border-zinc-700">{producer}</span>
                  ))}
                </div>
              </div>
            }
          </div>

          {/* Right Column */}
          <div>
            {/* Ratings */}
            {seriesItem.ratings && Object.keys(seriesItem.ratings).length > 0 &&
              <div className="mb-6">
                <div className="text-xs font-semibold uppercase tracking-wider text-zinc-300 mb-3 pb-1 border-b border-zinc-800">Ratings</div>
                <div className="grid grid-cols-2 gap-2">
                  {seriesItem.ratings.imdb &&
                    <div className="bg-zinc-950 rounded-md px-4 py-2 border border-zinc-800 text-center">
                      <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">IMDb</div>
                      <div className="text-yellow-400 font-semibold text-xl">{seriesItem.ratings.imdb}</div>
                    </div>
                  }
                  {seriesItem.ratings.rotten_tomatoes &&
                    <div className="bg-zinc-950 rounded-md px-4 py-2 border border-zinc-800 text-center">
                      <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">Rotten Tomatoes</div>
                      <div className="text-orange-600 font-semibold text-xl">{seriesItem.ratings.rotten_tomatoes}</div>
                    </div>
                  }
                  {seriesItem.ratings.metacritic &&
                    <div className="bg-zinc-950 rounded-md px-4 py-2 border border-zinc-800 text-center">
                      <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">Metacritic</div>
                      <div className="text-yellow-300 font-semibold text-xl">{seriesItem.ratings.metacritic}</div>
                    </div>
                  }
                  {seriesItem.ratings.user_average &&
                    <div className="bg-zinc-950 rounded-md px-4 py-2 border border-zinc-800 text-center">
                      <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">User Average</div>
                      <div className="text-white font-semibold text-xl">{seriesItem.ratings.user_average}</div>
                    </div>
                  }
                </div>
              </div>
            }

            {/* Production Info */}
            <div className="mb-6">
              <div className="text-xs font-semibold uppercase tracking-wider text-zinc-300 mb-3 pb-1 border-b border-zinc-800">Production</div>
              {seriesItem.production_companies && seriesItem.production_companies.length > 0 &&
                <div className="mb-3">
                  <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">Companies</div>
                  <div className="text-zinc-300 text-sm">{seriesItem.production_companies.join(', ')}</div>
                </div>
              }
              {seriesItem.countries && seriesItem.countries.length > 0 &&
                <div className="mb-3">
                  <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">Countries</div>
                  <div className="text-zinc-300 text-sm">{seriesItem.countries.join(', ')}</div>
                </div>
              }
              {seriesItem.languages && seriesItem.languages.length > 0 &&
                <div>
                  <div className="text-[11px] uppercase tracking-wider text-zinc-400 mb-1">Languages</div>
                  <div className="text-zinc-300 text-sm">{seriesItem.languages.join(', ')}</div>
                </div>
              }
            </div>
          </div>
        </div>

        {/* Episodes Table */}
        {seriesItem.episodes && seriesItem.episodes.length > 0 &&
          <div className="mt-2">
            <div className="text-xs font-semibold uppercase tracking-wider text-zinc-300 mb-3 pb-1 border-b border-zinc-800">Episodes ({seriesItem.episodes.length})</div>
            <table className="w-full border-separate border-spacing-0">
              <thead>
                <tr className="bg-zinc-950">
                  <th className="text-center py-2.5 px-3 rounded-tl-md text-zinc-400 text-xs uppercase tracking-wide w-16">#</th>
                  <th className="text-left py-2.5 px-3 text-zinc-400 text-xs uppercase tracking-wide">Title</th>
                  <th className="text-center py-2.5 px-3 rounded-tr-md text-zinc-400 text-xs uppercase tracking-wide w-24">Runtime</th>
                </tr>
              </thead>
              <tbody>
                {seriesItem.episodes.map((episode, idx) => (
                  <tr key={episode._id || idx} className={idx % 2 === 0 ? 'bg-zinc-800' : 'bg-zinc-900'}>
                    <td className="text-center py-2.5 px-3 border-b border-zinc-800 text-white font-semibold">{episode.episode_number}</td>
                    <td className="text-left py-2.5 px-3 border-b border-zinc-800 text-zinc-300">{episode.episode_title}</td>
                    <td className="text-center py-2.5 px-3 border-b border-zinc-800 text-zinc-400">{episode.runtime_minutes} min</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        }
      </div>

      {/* Footer / Back button */}
      <div className="bg-zinc-900 rounded-b-lg px-8 py-4 border border-zinc-800 border-t-0">
        <button
          type="button"
          className="py-2 px-6 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-base cursor-pointer transition"
          onClick={() => navigate(-1)}
        >
          Back to Series List
        </button>
      </div>
    </div>
  );
};

export default SeriesDetails;
