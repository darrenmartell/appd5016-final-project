import { useNavigate } from 'react-router-dom';
import { useParams, useOutletContext } from 'react-router-dom';

const UserDetails = () => {
  const navigate = useNavigate();
  const { users, isLoading, error } = useOutletContext();
  const { id } = useParams()

  if (error) return <p>An error occurred - {error.message}</p>;
  if (isLoading) return <p>Loading...</p>;

  const user = users.find(item => item._id === id);

  return (
    <div className="bg-zinc-900 rounded-lg shadow-lg p-8 my-8 mx-auto max-w-xl border border-zinc-800 text-zinc-300">
      <h2 className="text-3xl font-bold mb-4 text-white">User Details</h2>
      <div className="leading-relaxed">
        <div><strong className="text-white">ID:</strong> {user._id}</div>
        {(user.firstName && user.lastName) &&
          <div><strong className="text-white">Name:</strong> {user.firstName} {user.lastName}</div>
        }
        {user.email &&
          <div><strong className="text-white">Email:</strong> {user.email}</div>
        }
      </div >
      <div className="mt-4">
        <button
          type="button"
          className="flex-1 py-2 px-4 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-lg cursor-pointer transition"
          onClick={() => navigate(-1)}
        >
          Back to Users List
        </button>
      </div>
    </div>
  );
};

export default UserDetails;