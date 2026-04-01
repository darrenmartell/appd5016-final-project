import { useNavigate } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faPenToSquare, faTrash, faCircleInfo } from '@fortawesome/free-solid-svg-icons';
import { useOutletContext } from 'react-router-dom';


function SeriesTable() {
    const navigate = useNavigate();
    const { series, isLoading, error } = useOutletContext();

    if (error) return <p>An error occurred - {error.message}</p>;
    if (isLoading) return <p>Loading...</p>;

    return (
        <div className="bg-zinc-900 rounded-lg shadow-lg p-8 my-8 mx-auto max-w-4xl border border-zinc-800">
            <div className="flex justify-end mb-4">
                <button
                    className="py-2 px-6 bg-red-700 hover:bg-red-800 text-white border-none rounded font-bold text-base cursor-pointer transition"
                    onClick={() => navigate('/admin/series/add')}
                >
                    + Add Series
                </button>
            </div>
            {/* Responsive Table: Desktop and Tablet */}
            <div className="hidden sm:block overflow-x-auto">
                <table className="w-full border-separate border-spacing-0 table-fixed min-w-[480px] md:min-w-0">
                    <colgroup>
                        <col className="w-1/3 md:w-1/4" />
                        <col className="w-1/3 md:w-[320px]" />
                        <col className="w-1/3 md:w-[160px]" />
                    </colgroup>
                    <thead>
                        <tr className="bg-zinc-950">
                            <th className="text-left py-3 px-2 rounded-tl-lg text-zinc-300">Title</th>
                            <th className="py-3 px-2 text-zinc-300">Plot Summary</th>
                            <th className="py-3 px-2 rounded-tr-lg text-zinc-300 text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {
                            series.map((series, idx) => {
                                return (
                                    <tr key={series._id} className={idx % 2 === 0 ? 'bg-zinc-800' : 'bg-zinc-900'}>
                                        <td className="py-2.5 px-2 border-b border-zinc-800 text-white break-words align-top">
                                            <span className="block md:inline">{series.title}</span>
                                        </td>
                                        <td className="py-2.5 px-2 border-b border-zinc-800 text-zinc-300 break-words align-top">
                                            <span className="block md:inline">{series.plot_summary}</span>
                                        </td>
                                        <td className="py-2.5 px-2 border-b border-zinc-800 text-center align-top">
                                            <div className="flex flex-col md:flex-row md:justify-center gap-2 md:gap-2">
                                                <button onClick={() => navigate(`/admin/series/${series._id}/update`)} className="py-1 px-2.5 bg-red-700 hover:bg-red-800 text-white border-none rounded font-bold text-sm cursor-pointer transition" title="Edit">
                                                    <FontAwesomeIcon icon={faPenToSquare} />
                                                </button>
                                                <button onClick={() => navigate(`/admin/series/${series._id}/delete`)} className="py-1 px-2.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-sm cursor-pointer transition" title="Delete">
                                                    <FontAwesomeIcon icon={faTrash} />
                                                </button>
                                                <button onClick={() => navigate(`/admin/series/${series._id}/details`)} className="py-1 px-2.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-sm cursor-pointer transition" title="Details">
                                                    <FontAwesomeIcon icon={faCircleInfo} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })
                        }
                    </tbody>
                </table>
            </div>

            {/* Mobile/Narrowest View: Card Grid */}
            <div className="sm:hidden space-y-6">
                {series.map((series, idx) => (
                    <div key={series._id} className={`grid grid-cols-2 gap-2 rounded-lg border border-zinc-800 p-4 ${idx % 2 === 0 ? 'bg-zinc-800' : 'bg-zinc-900'}`}>
                        <div className="flex flex-col gap-4 text-xs text-zinc-400 font-semibold uppercase tracking-wider pt-1">
                            <span>Title</span>
                            <span>Plot Summary</span>
                            <span>Actions</span>
                        </div>
                        <div className="flex flex-col gap-4">
                            <span className="text-white font-bold break-words">{series.title}</span>
                            <span className="text-zinc-300 break-words">{series.plot_summary}</span>
                            <div className="flex gap-2">
                                <button onClick={() => navigate(`/admin/series/${series._id}/update`)} className="py-1 px-2.5 bg-red-700 hover:bg-red-800 text-white border-none rounded font-bold text-sm cursor-pointer transition" title="Edit">
                                    <FontAwesomeIcon icon={faPenToSquare} />
                                </button>
                                <button onClick={() => navigate(`/admin/series/${series._id}/delete`)} className="py-1 px-2.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-sm cursor-pointer transition" title="Delete">
                                    <FontAwesomeIcon icon={faTrash} />
                                </button>
                                <button onClick={() => navigate(`/admin/series/${series._id}/details`)} className="py-1 px-2.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-sm cursor-pointer transition" title="Details">
                                    <FontAwesomeIcon icon={faCircleInfo} />
                                </button>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}

export default SeriesTable