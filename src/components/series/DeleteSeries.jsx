import { useParams, useNavigate, useOutletContext } from 'react-router-dom';
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useAuthContext } from '../../context/AuthContext';
import config from '../../config';

const DeleteSeries = () => {
  const navigate = useNavigate();
  const { series } = useOutletContext();
  const { id } = useParams()

  const seriesItem = series.find(item => item._id === id);

  const queryClient = useQueryClient()
  const { token } = useAuthContext();

  const mutation = useMutation({
    mutationFn: async () => {
      const response = await fetch(`${config.API_URL}/series/${id}`, {
        method: 'DELETE',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
      })
      if (!response.ok) {
        throw new Error('Failed to delete series')
      }
      return response.json()
    },
    onSuccess: () => {
      console.log('Series deleted successfully')
      queryClient.invalidateQueries( { queryKey: ["seriesCache"]})
      navigate('/admin/series')
    },
    onError: (error) => {
      console.error(error)
    }
  })

  return (
    <div className="bg-zinc-900 rounded-lg shadow-lg p-8 my-8 mx-auto max-w-xl border border-zinc-800 text-zinc-300">
      <h2 className="text-3xl font-bold mb-4 text-white">Delete Series</h2>
      <div className="leading-relaxed">
        <div>
          <strong className="text-white">ID:</strong> {seriesItem._id}
        </div>
        {seriesItem.title &&
          <div>
            <strong className="text-white">Name:</strong> {seriesItem.title}
          </div>
        }
        {seriesItem.plot_summary &&
          <div>
            <strong className="text-white">Plot Summary:</strong> {seriesItem.plot_summary}
          </div>
        }
      </div>
      <div className="mt-4 flex gap-4">
        <button
          type="button"
          className="flex-1 py-2 px-4 bg-red-700 hover:bg-red-800 text-white border-none rounded font-bold text-lg cursor-pointer transition"
          onClick={() => mutation.mutate()}
        >
          Delete Series
        </button>
        <button
          type="button"
          className="flex-1 py-2 px-4 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-lg cursor-pointer transition"
          onClick={() => navigate(-1)}
        >
          Back to Series List
        </button>
      </div>
    </div>
  );
};

export default DeleteSeries;