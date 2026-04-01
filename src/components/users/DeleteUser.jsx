import { useParams, useNavigate, useOutletContext } from 'react-router-dom';
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useAuthContext } from '../../context/AuthContext';
import config from '../../config';

const DeleteUser = () => {
  const navigate = useNavigate();
  const { users } = useOutletContext();
  const { id } = useParams()
  const user = users.find(item => item._id === id);
  const userExists = !!user;
  const isLoggedInUser = user._id === useAuthContext().user?.id;

  const queryClient = useQueryClient()
  const { token } = useAuthContext();

  const mutation = useMutation({
    mutationFn: async () => {
      const response = await fetch(`${config.API_URL}/users/${id}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
      })
      return response.json()
    },
    onSuccess: () => {
      console.log('mutation was successful')
      queryClient.invalidateQueries({ queryKey: ["userCache"] })
      navigate('/admin/users')
    },
    onError: () => {
      console.error('mutation error')
    }
  })

  return (
    <div className="bg-zinc-900 rounded-lg shadow-lg p-8 my-8 mx-auto max-w-xl border border-zinc-800 text-zinc-300">
      <h2 className="text-3xl font-bold mb-4 text-white">Delete User</h2>
      {!userExists && <div>User not found</div>}
      {isLoggedInUser && <div>You cannot delete the currently logged in user</div>}
      {userExists && !isLoggedInUser &&
        <>
          <div className="leading-relaxed">
            <div><strong className="text-white">ID:</strong> {user._id}</div>
            {(user.firstName && user.lastName) &&
              <div><strong className="text-white">Name:</strong> {user.firstName} {user.lastName}</div>
            }
            {user.email &&
              <div><strong className="text-white">Email:</strong> {user.email}</div>
            }
          </div >

          <button
            type="button"
            className="flex-1 py-2 px-4 mt-4 mr-2 bg-red-700 hover:bg-red-800 text-white border-none rounded font-bold text-lg cursor-pointer transition"
            onClick={() => mutation.mutate()}
          >
            Delete User
          </button>
        </>
      }
      <button
        type="button"
        className="flex-1 py-2 px-4 mt-4 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-lg cursor-pointer transition"
        onClick={() => navigate(-1)}
      >
        Back to Users List
      </button>
    </div>
  );
};

export default DeleteUser;