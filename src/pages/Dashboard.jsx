import { useOutletContext, useNavigate } from 'react-router-dom';

const Dashboard = () => {
  const { series, isLoading, error, searchTerm } = useOutletContext();
  const navigate = useNavigate();

  let filteredSeries = series || [];

  if (searchTerm && searchTerm.trim() !== '') {
    filteredSeries = series.filter(s => {
      const term = searchTerm.trim().toLowerCase();
      // Combine all relevant fields into a single string for search purposes only
      const combined = [
        s.title,
        s.plot_summary,
        s.released_year,
        s.runtime_minutes,
        s.genres?.join(' '),
        s.countries?.join(' '),
        s.languages?.join(' '),
        s.producers?.join(' '),
        s.production_companies?.join(' '),
        s.cast?.join(' '),
        s.directors?.join(' '),
        s.ratings && typeof s.ratings === 'object'
          ? Object.entries(s.ratings)
              .filter(([_, v]) => v !== undefined && v !== null && v !== '')
              .map(([k]) => k.toString())
              .join(' ')
          : '',
        s.episodes ? s.episodes.map(ep => `${ep.episode_title} ${ep.runtime_minutes}`).join(' ') : ''
      ].join(' ').toLowerCase();

      console.log('Combined string for series:', combined); // Debugging log
      return combined.includes(term);
    });
  };

  return (
    <div>
      <h1 className="text-2xl py-4 font-bold text-white">Dashboard</h1>

      {error && <p className="text-[#ff6b6b]">Failed to load series: {error.message}</p>}
      {isLoading && <p className="text-[#b3b3b3]">Loading series...</p>}

      {!isLoading && !error && filteredSeries.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredSeries.map((item) => (
            <div
              key={item._id}
              onClick={() => navigate(`/admin/series/${item._id}/details`)}
              style={{
                background: '#222',
                border: '1px solid #333',
                borderRadius: 8,
                overflow: 'hidden',
                cursor: 'pointer',
                transition: 'border-color 0.2s, box-shadow 0.2s',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#e50914';
                e.currentTarget.style.boxShadow = '0 4px 16px rgba(229,9,20,0.15)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = '#333';
                e.currentTarget.style.boxShadow = 'none';
              }}
            >
              {/* Header */}
              <div style={{ padding: '16px 20px 12px', borderBottom: '1px solid #333' }}>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: '#fff', margin: 0, lineHeight: 1.3 }}>
                  {item.title || 'Untitled'}
                </h3>
                <div style={{ display: 'flex', gap: 12, marginTop: 6, fontSize: 13, color: '#888' }}>
                  {item.released_year && <span>{item.released_year}</span>}
                  {item.runtime_minutes && <span>{item.runtime_minutes} min</span>}
                  {item.episodes && item.episodes.length > 0 && (
                    <span>{item.episodes.length} ep{item.episodes.length !== 1 ? 's' : ''}</span>
                  )}
                </div>
              </div>

              {/* Genres */}
              {item.genres && item.genres.length > 0 && (
                <div style={{ padding: '10px 20px 0', display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {item.genres.map((genre, idx) => (
                    <span
                      key={idx}
                      style={{
                        background: '#e50914',
                        color: '#fff',
                        padding: '2px 10px',
                        borderRadius: 12,
                        fontSize: 11,
                        fontWeight: 600,
                      }}
                    >
                      {genre}
                    </span>
                  ))}
                </div>
              )}

              {/* Plot summary */}
              {item.plot_summary && (
                <div className="px-5 py-2 text-zinc-300 text-sm leading-relaxed whitespace-pre-line">
                  {item.plot_summary}
                </div>
              )}

              {/* Ratings */}
              {item.ratings && Object.keys(item.ratings).length > 0 && (
                <div style={{
                  padding: '8px 20px 16px',
                  display: 'flex',
                  gap: 12,
                  flexWrap: 'wrap',
                }}>
                  {item.ratings.imdb && (
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#888' }}>IMDb</div>
                      <div style={{ fontSize: 16, fontWeight: 700, color: '#f5c518' }}>{item.ratings.imdb}</div>
                    </div>
                  )}
                  {item.ratings.rotten_tomatoes && (
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#888' }}>RT</div>
                      <div style={{ fontSize: 16, fontWeight: 700, color: '#fa320a' }}>{item.ratings.rotten_tomatoes}</div>
                    </div>
                  )}
                  {item.ratings.metacritic && (
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#888' }}>MC</div>
                      <div style={{ fontSize: 16, fontWeight: 700, color: '#ffcc34' }}>{item.ratings.metacritic}</div>
                    </div>
                  )}
                  {item.ratings.user_average && (
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#888' }}>Users</div>
                      <div style={{ fontSize: 16, fontWeight: 700, color: '#fff' }}>{item.ratings.user_average}</div>
                    </div>
                  )}
                </div>
              )}

              {/* Cast preview */}
              {item.cast && item.cast.length > 0 && (
                <div style={{
                  padding: '0 20px 16px',
                  fontSize: 12,
                  color: '#666',
                }}>
                  {item.cast.slice(0, 3).join(', ')}
                  {item.cast.length > 3 && ` +${item.cast.length - 3} more`}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {!isLoading && !error && series.length === 0 && (
        <p className="text-[#b3b3b3]">No series found.</p>
      )}
    </div>
  );
};

export default Dashboard;
